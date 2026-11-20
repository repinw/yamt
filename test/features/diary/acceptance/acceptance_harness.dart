// Shared setup of the acceptance tests for the optional carryover and the
// week strip (#911). The expectations live in the test files; this file only
// drives the app: a fixed clock, a goal run, eaten kcal per day, pause and
// training days, the weight goal, and the mode chosen through the UI.
import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_transition_helpers.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';
import '../../../helpers/fake_accelerometer.dart';
import '../../../helpers/fake_health_steps_service.dart';
import '../../../helpers/long_press_test_utils.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';
import 'acceptance_contract.dart';

export 'acceptance_contract.dart';

/// Monday 2026-11-16, the first day of the run in most tests.
final DateTime runMonday = DateTime(2026, 11, 16);

/// The day [offset] days after [runMonday] (0 = Monday, 3 = Thursday).
DateTime runDay(int offset) => addLocalDays(runMonday, offset);

/// 10:00 on [day], the wall clock of a test that is "on" that day.
DateTime morningOf(DateTime day) => DateTime(day.year, day.month, day.day, 10);

class _MockUser extends Mock implements User {
  @override
  String get uid => 'user-1';

  @override
  bool get isAnonymous => false;
}

/// A goal of `kcal` that counts from the day `from` on, set on that day.
typedef NewGoal = ({DateTime from, double kcal});

/// A goal of [kcal] set on the day [setOn] that counts from [countsFrom]
/// ("Zielstart") on, stored as the app stores it: effective from the day it
/// is set, counting from its start (K49).
class GoalChange {
  /// Creates the change; [trainingWeekdays] replaces the training weekdays
  /// of the goal before it (1 = Monday), when given.
  const new({
    required this.setOn,
    required this.countsFrom,
    required this.kcal,
    this.trainingWeekdays,
  });

  /// The day the goal is set.
  final DateTime setOn;

  /// The goal's start ("Zielstart"), the first day it counts.
  final DateTime countsFrom;

  /// The goal's daily average.
  final double kcal;

  /// The training weekdays of the new goal, or null to keep the old ones.
  final List<int>? trainingWeekdays;
}

/// One account with a goal run, logged days and a fixed clock.
class DiaryAcceptanceHarness {
  /// Creates the account.
  ///
  /// [eaten] maps a day to the kcal logged on it; a day that is missing has
  /// no entries. [trainingDays] are days that the diary made training days
  /// (one session of [trainingSessionKcal] on top of the goal). [now] is the
  /// wall clock. Without [hasGoal] the account has no goal at all.
  /// [newGoal] is a second goal that counts from its start day on,
  /// set after the first one (K47); [goalChange] is one that may count from
  /// a later day than it is set (K49). [trainingWeekdays] are the planned
  /// training weekdays of the first goal (1 = Monday).
  new({
    required this.now,
    DateTime? goalStart,
    this.goalKcal = 2200,
    this.goalMode = CalorieGoalMode.lose,
    Map<DateTime, double> eaten = const <DateTime, double>{},
    Set<DateTime> pauseDays = const <DateTime>{},
    Set<DateTime> trainingDays = const <DateTime>{},
    double trainingSessionKcal = 250,
    bool hasGoal = true,
    BurnWeekRunState runState = const BurnWeekRunState.initial(),
    NewGoal? newGoal,
    GoalChange? goalChange,
    List<int> trainingWeekdays = const <int>[],
  }) : firestore = FakeFirebaseFirestore(),
       preferences = _phonePreferences(),
       runStateRepository = FakeBurnWeekRunStateRepository(runState),
       log = FakeCalorieLogRepository(),
       settings = FakeCalorieSettingsRepository(
         initialSettings: hasGoal
             ? _withGoalChange(
                 _withNewGoal(
                   CalorieGoalSettings.single(
                     dailyKcalGoal: goalKcal,
                     calculatorProfile: CalorieCalculatorProfile(
                       sex: CalorieCalculatorSex.male,
                       weightKg: 80,
                       heightCm: 180,
                       ageYears: 30,
                       activityLevel: 1.2,
                       goalMode: goalMode,
                       goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
                           ? 0
                           : 0.5,
                       trainingDayKcalOffset: trainingSessionKcal,
                       trainingWeekdays: trainingWeekdays,
                     ),
                     effectiveDate: goalStart ?? runMonday,
                     countingStartDate: goalStart ?? runMonday,
                     trainingWeekdays: trainingWeekdays,
                     trainingDayKcalOffset: trainingSessionKcal,
                     pauseDayKeys: [
                       for (final day in pauseDays) localDayKey(day),
                     ],
                   ).copyWith(
                     unplannedTrainingDayOverrides: {
                       for (final day in trainingDays) localDayKey(day): true,
                     },
                   ),
                   newGoal,
                 ),
                 goalChange,
               )
             : const CalorieGoalSettings.empty(),
       ) {
    for (final MapEntry(key: day, value: kcal) in eaten.entries) {
      unawaited(log.saveEntry(_entryOf(day, kcal)));
    }
  }

  /// The same account signed in on a second phone: the remote data is
  /// shared, the device storage is new (K5).
  new secondPhone(DiaryAcceptanceHarness first)
    : now = first.now,
      goalKcal = first.goalKcal,
      goalMode = first.goalMode,
      firestore = first.firestore,
      preferences = _phonePreferences(),
      runStateRepository = first.runStateRepository,
      log = first.log,
      settings = first.settings;

  /// Wall clock of the test.
  DateTime now;

  /// Goal of a normal day.
  final double goalKcal;

  /// Weight goal.
  final CalorieGoalMode goalMode;

  /// The account's remote documents that no fake below covers.
  final FakeFirebaseFirestore firestore;

  /// Device storage of this phone.
  final AppPreferences preferences;

  /// Run state of the account.
  final FakeBurnWeekRunStateRepository runStateRepository;

  /// Logged food of the account.
  final FakeCalorieLogRepository log;

  /// Goal settings of the account.
  final FakeCalorieSettingsRepository settings;

  /// Navigator of the pumped app, to open more pages over the diary.
  final navigatorKey = GlobalKey<NavigatorState>();

  /// The container of the pumped app.
  late ProviderContainer container;

  var _nextId = 0;

  static CalorieGoalSettings _withNewGoal(
    CalorieGoalSettings settings,
    NewGoal? goal,
  ) => goal == null
      ? settings
      : _withGoalChange(
          settings,
          GoalChange(setOn: goal.from, countsFrom: goal.from, kcal: goal.kcal),
        );

  /// [settings] after [change], through the domain call that the app's goal
  /// save makes (`transitionToCalculatedGoal`): a start after the day it is
  /// set makes the goal effective on that day and counting from its start.
  static CalorieGoalSettings _withGoalChange(
    CalorieGoalSettings settings,
    GoalChange? change,
  ) {
    if (change == null) return settings;
    final today = normalizeLocalDay(change.setOn);
    final start = normalizeLocalDay(change.countsFrom);
    final effective = start.isAfter(today) ? today : start;
    final profile = settings.goalHistory.last.calculatorProfile!;
    final weekdays = change.trainingWeekdays;
    final next = settings.applyGoalChange(
      changedAt: goalChangeTimestamp(
        normalizedEffectiveDate: effective,
        normalizedToday: today,
        now: morningOf(today),
      ),
      dailyKcalGoal: change.kcal,
      calculatorProfile: weekdays == null
          ? profile
          : profile.copyWith(trainingWeekdays: weekdays),
      countingStartDate: start,
      source: CalorieGoalSource.calculator,
      replaceFutureHistory: true,
    );
    final added = next.goalHistory.last;
    if (next.goalHistory.length != settings.goalHistory.length + 1 ||
        !isSameLocalDay(added.effectiveDate, effective) ||
        !isSameLocalDay(added.effectiveCountingStartDate, start)) {
      throw StateError('The harness did not store the goal change as the app.');
    }
    return next;
  }

  /// Sets [goal], a new goal that counts from its start day on,
  /// while the app is open (K47, K48).
  Future<void> setNewGoal(WidgetTester tester, NewGoal goal) async {
    await tester.runAsync(() async {
      final current = await settings.readSettings();
      await settings.saveSettings(_withNewGoal(current, goal));
    });
    await settle(tester);
  }

  /// Sets [change] while the app is open (K49).
  Future<void> setGoalChange(WidgetTester tester, GoalChange change) async {
    await tester.runAsync(() async {
      final current = await settings.readSettings();
      await settings.saveSettings(_withGoalChange(current, change));
    });
    await settle(tester);
  }

  static MemoryAppPreferences _phonePreferences() => MemoryAppPreferences(
    completedCalorieGoalOnboardingUserIds: const {'user-1'},
    initialInts: const {healthStepsPreferenceKey: 1},
  );

  CalorieEntry _entryOf(DateTime day, double kcal) {
    final at = DateTime(day.year, day.month, day.day, 12);
    _nextId += 1;
    final id = '${localDayKey(day)}-$_nextId';
    return CalorieEntry.create(
      id: id,
      userId: 'user-1',
      name: 'Essen $id',
      mealType: MealType.lunch,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: kcal,
      per100Protein: kcal * 0.25 / 4,
      per100Carbs: kcal * 0.5 / 4,
      per100Fat: kcal * 0.25 / 9,
      loggedAt: at,
      createdAt: at,
      updatedAt: at,
    );
  }

  /// Replaces everything logged on [day] with one entry of [kcal], as an
  /// edit of an earlier day does (K40).
  Future<void> changeEaten(
    WidgetTester tester,
    DateTime day,
    double kcal,
  ) async {
    final old = log.entries.where(
      (entry) => isSameLocalDay(entry.loggedAt, day),
    );
    await tester.runAsync(() async {
      for (final entry in old.toList()) {
        await log.deleteEntry(entry.id);
      }
    });
    await eat(tester, day, kcal);
  }

  /// Closes the app and opens the diary again on [now], on the same phone:
  /// the device storage and the account stay (K42).
  Future<void> restart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    await pumpDiary(tester);
  }

  /// Logs [kcal] more on [day] through the app's entry saver, as the eat
  /// flows do.
  Future<void> eat(WidgetTester tester, DateTime day, double kcal) async {
    final save = container.read(calorieEntrySaverProvider);
    await tester.runAsync(() => save(_entryOf(day, kcal)));
    await settle(tester);
  }

  /// The overrides of one phone signed in to this account.
  List<Override> overrides() => [
    clockProvider.overrideWithValue(() => now),
    appPreferencesProvider.overrideWithValue(preferences),
    firebaseFirestoreProvider.overrideWithValue(firestore),
    authStateChangesProvider.overrideWith(
      (ref) => Stream<User?>.value(_MockUser()),
    ),
    userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
    householdDataOwnerUserIdProvider.overrideWith((ref) => 'user-1'),
    calorieSettingsRepositoryProvider.overrideWithValue(settings),
    calorieLogRepositoryProvider.overrideWithValue(log),
    // The shopping list waits for the update status before it rewrites.
    appUpdateStatusProvider.overrideWith(
      (ref) => Stream.value(const AppUpToDate()),
    ),
    // The Einkauf tool in the bar reads the list; an empty fake keeps it off
    // the real repository.
    shoppingListRepositoryProvider.overrideWithValue(
      FakeShoppingListRepository(),
    ),
    plannedEntryRepositoryProvider.overrideWithValue(
      FakePlannedEntryRepository(),
    ),
    burnWeekRunStateRepositoryProvider.overrideWithValue(runStateRepository),
    burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
    burnWeekLiveSyncProvider.overrideWith((ref) => null),
    healthStepsServiceProvider.overrideWithValue(FakeHealthStepsService()),
    healthConnectionServiceProvider.overrideWithValue(
      FakeHealthConnectionService(
        const HealthConnectionStatus(
          platform: HealthPlatform.android,
          healthConnectAvailability: HealthConnectAvailability.available,
          permissionState: HealthPermissionState.granted,
          historyAccess: HealthHistoryAccess.granted,
        ),
      ),
    ),
    healthWeightServiceProvider.overrideWithValue(FakeHealthWeightService([])),
    manualHealthWeightRepositoryProvider.overrideWithValue(
      FakeManualHealthWeightRepository([]),
    ),
    // The criteria's examples keep the goal fixed (2.200 on every day); the
    // daily TDEE would move it with what was eaten, so it stays out here.
    goalTdeeOffsetsByDayProvider.overrideWith((ref) async {
      final settings = await ref.watch(calorieGoalControllerProvider.future);
      return GoalTdeeOffsets(settings: settings, byDay: const {});
    }),
  ];

  /// Opens the diary in German on today.
  Future<void> pumpDiary(WidgetTester tester) async {
    await pumpApp(tester, const DiaryPage(includeHomeShellChrome: true));
  }

  /// Pumps [home] in German with this account.
  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    // 560 x 1600 logical pixels: the diary's widest content, tall enough
    // for the budget, week and steps cards. The test font is wider than the
    // app's, and a training day's toggle row overflows a narrower card.
    tester.view
      ..physicalSize = const Size(1400, 4000)
      ..devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    // The gold foil of the budget card listens to the accelerometer.
    FakeAccelerometer();
    container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    // Unmounts the app first, while the fake sensor still answers.
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: home),
        ),
      ),
    );
    await settle(tester);
    await _dismissWeeklyCheckIn(tester);
  }

  /// The weekly check-in of a finished run asks for a weight first; the
  /// tests here are not about it, so they put it off as a user would.
  Future<void> _dismissWeeklyCheckIn(WidgetTester tester) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;
    final later = find.text(l10n.caloriesWeeklyCheckInLaterAction);
    if (later.evaluate().isNotEmpty) {
      await tester.tap(later.last);
      await settle(tester);
    }
  }

  /// Opens [page] over the diary, in the same app.
  Future<void> push(WidgetTester tester, Widget page) async {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await settle(tester);
  }

  /// Closes the page on top.
  Future<void> pop(WidgetTester tester) async {
    navigatorKey.currentState!.pop();
    await settle(tester);
  }
}

/// Lets streams and timers of the fakes run, then pumps a few frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 1));
}

/// All texts under [finder] (itself included), joined by a space; empty when
/// [finder] finds nothing.
String textUnder(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) return '';
  return tester
      .widgetList<Text>(
        find.descendant(
          of: finder,
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .join(' ')
      .trim();
}

/// Every text on the screen, in tree order.
List<String> allTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .toList();

/// The text of the budget card's big number.
String budgetKcalText(WidgetTester tester) =>
    textUnder(tester, find.byKey(DiaryBudgetCardKeys.kcalValue));

/// The words under the budget card's big number.
String budgetUnitText(WidgetTester tester) =>
    textUnder(tester, find.byKey(DiaryBudgetCardKeys.kcalUnit));

/// Every text of the budget card.
String budgetCardText(WidgetTester tester) =>
    textUnder(tester, find.byKey(DiaryBudgetCardKeys.card));

/// Every text of the ledger in the budget card's details.
String ledgerText(WidgetTester tester) =>
    textUnder(tester, find.byKey(DiaryBudgetCardKeys.ledger));

/// The number under the week card's field at [index]; empty when nothing
/// stands there.
String dayNumberText(WidgetTester tester, int index) =>
    textUnder(tester, find.byKey(WeekCardKeys.dayNumber(index)));

/// The name under the week card's field at [index].
String dayNameText(WidgetTester tester, int index) =>
    textUnder(tester, find.byKey(WeekCardKeys.dayName(index)));

/// The number of the week card's fields, counted from index 0 on as long as
/// they follow each other.
int weekFieldCount(WidgetTester tester) {
  var count = 0;
  while (find.byKey(WeekCardKeys.day(count)).evaluate().isNotEmpty) {
    count += 1;
  }
  return count;
}

/// The names under the week card's fields, in their order.
List<String> weekDayNames(WidgetTester tester) => [
  for (var index = 0; index < weekFieldCount(tester); index += 1)
    dayNameText(tester, index),
];

/// The index of the one field of the week card that has the frame.
int? framedWeekDay(WidgetTester tester) {
  expect(find.byKey(WeekCardKeys.frame), findsOneWidget);
  for (var index = 0; index < 7; index += 1) {
    if (partOfDay(index, WeekCardKeys.frame).evaluate().isNotEmpty) {
      return index;
    }
  }
  return null;
}

/// [part] inside the week card's field at [index].
Finder partOfDay(int index, Key part) => find.descendant(
  of: find.byKey(WeekCardKeys.day(index)),
  matching: find.byKey(part),
);

/// The fill colour of the first widget that [finder] finds: a `ColoredBox`,
/// a `Container` or a `DecoratedBox` with a `BoxDecoration`, itself or the
/// first such widget below it.
Color? fillColorOf(WidgetTester tester, Finder finder) {
  for (final element
      in find
          .descendant(
            of: finder,
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox || w is Container || w is DecoratedBox,
            ),
            matchRoot: true,
          )
          .evaluate()) {
    final color = _fill(element.widget);
    if (color != null) return color;
  }
  return null;
}

Color? _fill(Widget widget) {
  return switch (widget) {
    ColoredBox(:final color) => color,
    Container(:final color?) => color,
    Container(decoration: BoxDecoration(:final color?)) => color,
    DecoratedBox(decoration: BoxDecoration(:final color?)) => color,
    _ => null,
  };
}

/// Every fill colour under [finder].
List<Color> fillColorsUnder(WidgetTester tester, Finder finder) => [
  for (final element
      in find
          .descendant(
            of: finder,
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox || w is Container || w is DecoratedBox,
            ),
            matchRoot: true,
          )
          .evaluate())
    ?_fill(element.widget),
];

/// The colour that the text [finder] is drawn in.
Color? textColorOf(WidgetTester tester, Finder finder) {
  final element = find
      .descendant(of: finder, matching: find.byType(Text), matchRoot: true)
      .evaluate()
      .first;
  final text = element.widget as Text;
  return DefaultTextStyle.of(element).style.merge(text.style).color ??
      text.textSpan?.style?.color;
}

/// The weight of the text [finder].
FontWeight textWeightOf(WidgetTester tester, Finder finder) {
  final element = find
      .descendant(of: finder, matching: find.byType(Text), matchRoot: true)
      .evaluate()
      .first;
  final text = element.widget as Text;
  return DefaultTextStyle.of(element).style.merge(text.style).fontWeight ??
      FontWeight.normal;
}

/// The error colour of the app, which the criteria call "red".
Color redOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(DiaryBudgetCardKeys.card)))
        .colorScheme
        .error;

/// Taps the budget card's "Details" chip.
Future<void> toggleDetails(WidgetTester tester) async {
  await tester.tap(find.byKey(DiaryBudgetCardKeys.detailsChip));
  await settle(tester);
}

/// Opens the week card's menu with a long press (K1).
Future<void> openWeekCardMenu(WidgetTester tester) async {
  expect(
    find.byKey(WeekCardKeys.card),
    findsOneWidget,
    reason: 'the week card (#911) is shown, so it can be held for its menu',
  );
  await longPressOpeningRoute(tester, find.byKey(WeekCardKeys.card));
  await settle(tester);
}

/// Picks [mode] in the open menu of the week card or in the settings.
Future<void> pickMode(WidgetTester tester, WeekBalanceMode mode) async {
  final option = find.byKey(WeekCardKeys.modeOption(mode));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await settle(tester);
}

/// Closes the week card's menu when it is still open.
Future<void> closeMenuIfOpen(WidgetTester tester) async {
  if (find.byKey(WeekCardKeys.menu).evaluate().isNotEmpty) {
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
  }
}

/// Picks [mode] through the week card's menu, as a user would.
Future<void> chooseModeInDiary(
  WidgetTester tester,
  WeekBalanceMode mode,
) async {
  await openWeekCardMenu(tester);
  await pickMode(tester, mode);
  await closeMenuIfOpen(tester);
}

/// Waits until no snack bar is on the screen. The app's snack bars sit at
/// the top, over the day navigator, so a user lets one pass (four seconds,
/// K41) before paging.
Future<void> waitForSnackBarToPass(WidgetTester tester) async {
  final snackBar = find.byType(AppSnackBarView);
  if (snackBar.evaluate().isEmpty) return;
  for (var i = 0; i < 10 && snackBar.evaluate().isNotEmpty; i += 1) {
    await tester.pump(const Duration(seconds: 1));
  }
  expect(snackBar, findsNothing, reason: 'the snack bar hides itself');
  await settle(tester);
}

/// Pages the diary one day back.
Future<void> previousDay(WidgetTester tester, {int times = 1}) async {
  for (var i = 0; i < times; i += 1) {
    await waitForSnackBarToPass(tester);
    await tester.tap(find.byKey(DiaryDayNavigatorKeys.previous));
    await settle(tester);
  }
}

/// Pages the diary one day on.
Future<void> nextDay(WidgetTester tester, {int times = 1}) async {
  for (var i = 0; i < times; i += 1) {
    await waitForSnackBarToPass(tester);
    await tester.tap(find.byKey(DiaryDayNavigatorKeys.next));
    await settle(tester);
  }
}

/// Formats [kcal] like the criteria: dot for thousands.
String de(num kcal) {
  final digits = kcal.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i += 1) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// A signed carryover like the criteria: "−125", "+350" (U+2212 minus).
String signed(num kcal) => kcal < 0 ? '−${de(kcal)}' : '+${de(kcal)}';

/// The button "Wochentag abschließen" on the shown day's budget card.
Finder get closeDayButton => find.descendant(
  of: find.byKey(DiaryBudgetCardKeys.card),
  matching: find.byKey(DiaryBudgetCardKeys.closePreviousDay),
);

/// The button "Wochentag abgeschlossen" on the shown day's budget card.
Finder get reopenDayButton => find.descendant(
  of: find.byKey(DiaryBudgetCardKeys.card),
  matching: find.byKey(DiaryBudgetCardKeys.reopenPreviousDay),
);

/// Taps "Wochentag abschließen" on the shown day (tomorrow), K38, K39.
Future<void> closeToday(WidgetTester tester) async {
  expect(
    closeDayButton,
    findsOneWidget,
    reason: "tomorrow's budget card offers to close today (K38)",
  );
  await tester.ensureVisible(closeDayButton);
  await tester.tap(closeDayButton);
  await settle(tester);
}

/// Taps "Wochentag abgeschlossen" on the shown day (tomorrow), K41.
Future<void> reopenToday(WidgetTester tester) async {
  expect(
    reopenDayButton,
    findsOneWidget,
    reason: "tomorrow's budget card shows the closed day (K41)",
  );
  await tester.ensureVisible(reopenDayButton);
  await tester.tap(reopenDayButton);
  await settle(tester);
}

/// The undo action of the snack bar on the screen.
Finder get undoAction => find.text('Rückgängig');
