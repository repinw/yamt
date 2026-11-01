import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_kcal_column.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/auth_user_data_key_session.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../../helpers/system_back_test_utils.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

void main() {
  testWidgets('loading skeleton reserves daily balance card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: DiaryBalanceLoading(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byType(DiaryBalanceLoading)).height,
      greaterThan(150),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a normal day shows the kcal left in big numbers', (
    tester,
  ) async {
    await _pumpToday(tester);

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,200');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal left');
    // No plans, so no "After plan"; the details stay closed.
    expect(find.byKey(DiaryBudgetCardKeys.afterPlanChip), findsNothing);
    expect(find.byKey(DiaryBudgetCardKeys.ledger), findsNothing);
    expect(find.byKey(DiaryBudgetCardKeys.notCountingNote), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Eaten" shows the kcal eaten of the target until "Left"', (
    tester,
  ) async {
    await _pumpToday(tester, showDetails: true);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: true)));
    await tester.pumpAndSettle();

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '800');
    expect(
      _textOf(tester, DiaryBudgetCardKeys.kcalUnit),
      'kcal eaten\nof 2,000',
    );
    // The unit line already says eaten of target.
    expect(find.byKey(DiaryBudgetCardKeys.kcalTotal), findsNothing);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: false)));
    await tester.pumpAndSettle();

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,200');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal left');
    expect(tester.takeException(), isNull);
  });

  testWidgets('over the target the overage shows in the error color', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 28, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 2500],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(selectedDay),
      ),
      themeMode: ThemeMode.dark,
    );

    final value = tester.widget<Text>(
      find.byKey(DiaryBudgetCardKeys.kcalValue),
    );
    expect(value.data, '+500');
    expect(
      value.style?.color,
      Theme.of(tester.element(find.byType(DiaryBalanceCard))).colorScheme.error,
    );
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal over');
  });

  testWidgets('a full negative carryover is shown, not clamped', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 28, 12);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 0],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(selectedDay),
      ),
      todayFlexibleGoalKcal: -838,
    );

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '+838');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal over');
  });

  testWidgets('a pause day shows its word and what was eaten', (tester) async {
    final today = normalizeLocalDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1531],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(today),
        runWeekNumber: 2,
      ),
      isPauseDay: true,
    );

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), 'Pause day');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), '1,531 kcal eaten');
    expect(find.text('Ignored for learning'), findsOneWidget);
    // A pause day only shows what was eaten.
    expect(
      find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: true)),
      findsNothing,
    );
    expect(find.byKey(DiaryBudgetCardKeys.detailsChip), findsOneWidget);
  });

  testWidgets('the details chip opens the ledger and the week', (tester) async {
    await _pumpToday(tester, showDetails: true);

    expect(find.byKey(DiaryBudgetCardKeys.ledger), findsOneWidget);
    expect(find.byKey(DiaryBudgetCardKeys.weekStrip), findsOneWidget);
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalTotal), '800 / 2,000 kcal');
    expect(
      find.descendant(
        of: find.byKey(DiaryBudgetCardKeys.ledgerTotal),
        matching: find.text('1,200'),
      ),
      findsOneWidget,
    );
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('−800'), findsOneWidget);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.detailsChip));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryBudgetCardKeys.ledger), findsNothing);
    expect(find.byKey(DiaryBudgetCardKeys.weekStrip), findsNothing);
  });

  testWidgets('"All days" opens the budget sheet', (tester) async {
    final selectedDay = normalizeLocalDay(DateTime.now());

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 800],
      runState: const BurnWeekRunState.initial(),
      showDetails: true,
    );

    await tester.ensureVisible(find.byKey(DiaryBudgetCardKeys.allDaysLink));
    await tester.tap(find.byKey(DiaryBudgetCardKeys.allDaysLink));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsSheet),
      findsOneWidget,
    );
    expect(find.text('Daily budget details'), findsOneWidget);
  });

  testWidgets('a practice day keeps the card and adds a note at the bottom', (
    tester,
  ) async {
    final today = normalizeLocalDay(DateTime.now());
    final startDate = nextLocalDay(today);

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: startDate,
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
      goalKcal: 0,
      todayFlexibleGoalKcal: 0,
      goalStartsInFuture: true,
      nextGoalStartDate: startDate,
      futureGoalKcal: 1200,
    );

    // The day is measured against the goal that starts later.
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '300');
    expect(find.textContaining('Practice day · counts from'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(DiaryBudgetCardKeys.notCountingNote)).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(DiaryBudgetCardKeys.kcalValue)).dy,
      ),
    );
  });

  testWidgets('a pending new run shows a note like a practice day', (
    tester,
  ) async {
    final today = normalizeLocalDay(DateTime.now());
    final restartDate = addLocalDays(today, 1);

    await _pumpBalanceCard(
      tester,
      selectedDay: today,
      weekStartDate: today,
      dayTotals: const [0, 0, 0, 0, 0, 0, 500],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(restartDate),
      ),
    );

    expect(find.byKey(DiaryBudgetCardKeys.notCountingNote), findsOneWidget);
    expect(find.textContaining('Run ended · new run counts from'), findsOne);
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,500');
  });

  testWidgets('tomorrow closes the day before and offers undo', (tester) async {
    await _pumpTomorrow(tester, isPreviousDayClosed: false);
    final repository = _closedDayRepository(tester);

    // The whole of tomorrow is a plan.
    expect(
      _textOf(tester, DiaryBudgetCardKeys.kcalUnit),
      'kcal left after plan',
    );
    expect(find.text('Close Sunday'), findsOneWidget);
    expect(find.byKey(DiaryBudgetCardKeys.reopenPreviousDay), findsNothing);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.closePreviousDay));
    await tester.pumpAndSettle();

    expect(repository.readClosedDay(), DateTime(2026, 4, 26));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repository.readClosedDay(), isNull);
  });

  testWidgets('tomorrow reopens the closed day before', (tester) async {
    await _pumpTomorrow(tester, isPreviousDayClosed: true);
    final repository = _closedDayRepository(tester);
    await repository.saveClosedDay(DateTime(2026, 4, 26));

    // Closed, tomorrow counts like a started day.
    expect(find.text('Sunday closed'), findsOneWidget);
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,318');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal left');

    await tester.tap(find.byKey(DiaryBudgetCardKeys.reopenPreviousDay));
    await tester.pumpAndSettle();

    expect(repository.readClosedDay(), isNull);
  });

  testWidgets('a closed tomorrow counts its plans until the chip is off', (
    tester,
  ) async {
    await _pumpTomorrow(
      tester,
      isPreviousDayClosed: true,
      showDetails: true,
      plans: [_breakfastPlan],
    );

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,018');
    expect(
      _textOf(tester, DiaryBudgetCardKeys.kcalUnit),
      'kcal left after plan',
    );
    expect(find.text('Planned · counted'), findsOneWidget);
    expect(
      _textOf(tester, DiaryBudgetCardKeys.kcalTotal),
      '1,200 / 2,218 kcal\n300 planned',
    );

    await tester.tap(find.byKey(DiaryBudgetCardKeys.afterPlanChip));
    await tester.pumpAndSettle();

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,318');
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal left');
    expect(find.text('Planned · counted'), findsNothing);
    expect(_textOf(tester, DiaryBudgetCardKeys.kcalTotal), '900 / 2,218 kcal');
  });

  testWidgets('"Eaten" counts the plans in while "After plan" is on', (
    tester,
  ) async {
    await _pumpTomorrow(
      tester,
      isPreviousDayClosed: true,
      plans: [_breakfastPlan],
    );

    await tester.tap(find.byKey(DiaryBudgetCardKeys.viewSegment(eaten: true)));
    await tester.pumpAndSettle();

    expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,200');
    expect(
      _textOf(tester, DiaryBudgetCardKeys.kcalUnit),
      'kcal with plan\nof 2,218',
    );
  });

  testWidgets('a day without a previous-day carryover offers no close', (
    tester,
  ) async {
    final now = DateTime(2026, 4, 26, 20);
    final selectedDay = DateTime(2026, 4, 27);

    await _pumpBalanceCard(
      tester,
      now: now,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 900],
      runState: const BurnWeekRunState.initial(),
    );

    expect(find.byKey(DiaryBudgetCardKeys.closePreviousDay), findsNothing);
  });

  testWidgets('keeps Burn Week live sync subscribed on non-live days', (
    tester,
  ) async {
    final selectedDay = addLocalDays(DateTime.now(), -1);
    var syncWatchCount = 0;

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: localDayKey(selectedDay),
      ),
      onBurnWeekLiveSyncWatch: () {
        syncWatchCount += 1;
      },
    );

    expect(syncWatchCount, greaterThan(0));
  });

  testWidgets('shows retry content when week overview fails', (tester) async {
    final selectedDay = addLocalDays(DateTime.now(), -1);

    await _pumpBalanceCard(
      tester,
      selectedDay: selectedDay,
      weekStartDate: selectedDay,
      dayTotals: const [0, 0, 0, 0, 0, 0, 1000],
      runState: const BurnWeekRunState.initial(),
      weekOverviewThrows: true,
    );

    expect(find.text('Balance could not be loaded'), findsOneWidget);
    expect(find.byKey(DiaryBalanceCardKeys.retryButton), findsOneWidget);

    await tester.tap(find.byKey(DiaryBalanceCardKeys.retryButton));
    await tester.pump();

    expect(find.byKey(DiaryBalanceCardKeys.retryButton), findsOneWidget);
  });

  group('pace marker', () {
    final marker = find.byKey(DiaryBudgetLine.paceKey);

    testWidgets('a long press on the card opens its menu', (tester) async {
      await _pumpToday(tester);
      expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);

      await tester.longPress(find.byKey(DiaryBudgetCardKeys.card));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBudgetCardKeys.menu), findsOneWidget);
      expect(find.byKey(DiaryBudgetCardKeys.paceSwitch), findsOneWidget);
    });

    testWidgets('a screen reader opens the menu with an action of the card, '
        'without a long press', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpToday(tester);
      final openMenu = CustomSemanticsAction(
        label: AppLocalizations.of(
          tester.element(find.byKey(DiaryBudgetCardKeys.card)),
        )!.diaryBudgetMenuOpen,
      );
      final card = find.semantics.byPredicate(
        (node) =>
            node.getSemanticsData().customSemanticsActionIds?.contains(
              CustomSemanticsAction.getIdentifier(openMenu),
            ) ??
            false,
      );
      expect(card, findsOne);
      expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);

      tester.semantics.customAction(card, openMenu);
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBudgetCardKeys.menu), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a tap on the card opens no menu', (tester) async {
      await _pumpToday(tester);

      await tester.tap(find.byKey(DiaryBudgetCardKeys.card));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);
    });

    testWidgets('is not on the kcal line until the user turns it on', (
      tester,
    ) async {
      await _pumpToday(tester);

      expect(marker, findsNothing);
    });

    testWidgets("shows where today's kcal should be by now once it is on", (
      tester,
    ) async {
      await _pumpToday(tester, paceMarkerOn: true);

      // At 12:00 the standard day has 51.25 % of 2,000 kcal behind it.
      expect(marker, findsOneWidget);
      final line = tester.getRect(
        find.descendant(
          of: find.byType(DiaryBudgetKcalColumn),
          matching: find.byType(DiaryBudgetLine),
        ),
      );
      expect(
        tester.getCenter(marker).dx - line.left,
        closeTo(line.width * 0.5125 / AppBudgetCard.lineScale, 1e-3),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('is not on a past day', (tester) async {
      final selectedDay = DateTime(2026, 4, 27);
      await _pumpBalanceCard(
        tester,
        now: DateTime(2026, 4, 28, 12),
        selectedDay: selectedDay,
        weekStartDate: selectedDay,
        dayTotals: const [0, 0, 0, 0, 0, 0, 800],
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: localDayKey(selectedDay),
        ),
        paceMarkerOn: true,
      );

      expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), '1,200');
      expect(marker, findsNothing);
    });

    testWidgets('is not on a day to come', (tester) async {
      await _pumpTomorrow(
        tester,
        isPreviousDayClosed: true,
        paceMarkerOn: true,
      );

      expect(_textOf(tester, DiaryBudgetCardKeys.kcalUnit), 'kcal left');
      expect(marker, findsNothing);
    });

    testWidgets('is not on a pause day, which has no target to pace', (
      tester,
    ) async {
      final today = DateTime(2026, 4, 27);
      await _pumpBalanceCard(
        tester,
        now: DateTime(2026, 4, 27, 12),
        selectedDay: today,
        weekStartDate: today,
        dayTotals: const [0, 0, 0, 0, 0, 0, 1531],
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: localDayKey(today),
          runWeekNumber: 2,
        ),
        isPauseDay: true,
        paceMarkerOn: true,
      );

      expect(_textOf(tester, DiaryBudgetCardKeys.kcalValue), 'Pause day');
      expect(marker, findsNothing);
    });

    testWidgets("the menu's switch puts it on the kcal line and takes it "
        'off again', (tester) async {
      await _pumpToday(tester);
      final preferences = ProviderScope.containerOf(
        tester.element(find.byType(DiaryBalanceCard)),
      ).read(appPreferencesProvider);

      await tester.longPress(find.byKey(DiaryBudgetCardKeys.card));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DiaryBudgetCardKeys.paceSwitch));
      await tester.pumpAndSettle();

      expect(marker, findsOneWidget);
      expect(preferences.getIntSync('diary_pace_marker_v1'), 1);

      await pressSystemBack(tester);
      expect(find.byKey(DiaryBudgetCardKeys.menu), findsNothing);
      expect(marker, findsOneWidget);

      await tester.longPress(find.byKey(DiaryBudgetCardKeys.card));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DiaryBudgetCardKeys.paceSwitch));
      await tester.pumpAndSettle();

      expect(marker, findsNothing);
      expect(preferences.getIntSync('diary_pace_marker_v1'), isNull);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpBalanceCard(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  required BurnWeekRunState runState,
  VoidCallback? onBurnWeekLiveSyncWatch,
  VoidCallback? onWeekOverviewRead,
  FutureOr<CalorieWeekOverview> Function()? weekOverviewBuilder,
  List<ProviderObserver> observers = const <ProviderObserver>[],
  bool settle = true,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  ThemeMode themeMode = ThemeMode.light,
  bool isPauseDay = false,
  ValueChanged<DateTime>? onRestartRunFrom,
  bool weekOverviewThrows = false,
  bool showDetails = false,
  DateTime? now,
  double? previousDayCarryoverKcal,
  bool isPreviousDayClosed = false,
  List<CalorieEntry> plans = const <CalorieEntry>[],
  bool paceMarkerOn = false,
}) async {
  final normalizedSelectedDay = normalizeLocalDay(selectedDay);
  final weekOverview = _weekOverview(
    selectedDay: normalizedSelectedDay,
    weekStartDate: weekStartDate,
    dayTotals: dayTotals,
    goalKcal: goalKcal,
    baseGoalKcal: baseGoalKcal,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
    isPauseDay: isPauseDay,
    previousDayCarryoverKcal: previousDayCarryoverKcal,
    isPreviousDayClosed: isPreviousDayClosed,
  );
  final selectedDayOverview = weekOverview.days.last;
  final repository = FakeCalorieLogRepository();
  final auth = _MockFirebaseAuth();
  addTearDown(repository.dispose);
  when(() => auth.currentUser).thenReturn(null);

  final preferences = MemoryAppPreferences(
    initialInts: {if (paceMarkerOn) 'diary_pace_marker_v1': 1},
  );
  await tester.pumpWidget(
    ProviderScope(
      observers: observers,
      overrides: [
        if (now != null) clockProvider.overrideWithValue(() => now),
        appPreferencesProvider.overrideWithValue(preferences),
        closedDayRepositoryProvider.overrideWithValue(
          ClosedDayRepository(preferences, 'user-1'),
        ),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
        firebaseAuthProvider.overrideWithValue(auth),
        userDataCipherProvider.overrideWithValue(testUserDataCipher),
        calorieLogRepositoryProvider.overrideWithValue(repository),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(plans: plans),
        ),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekLiveSyncProvider.overrideWith((ref) {
          onBurnWeekLiveSyncWatch?.call();
          return null;
        }),
        calorieWeekOverviewForWindowProvider(normalizedSelectedDay)
            .overrideWith((ref) {
              onWeekOverviewRead?.call();
              if (weekOverviewThrows) {
                throw StateError('week overview failed');
              }
              final builder = weekOverviewBuilder;
              if (builder != null) {
                return builder();
              }
              return weekOverview;
            }),
        calorieWeekDayOverviewForDateProvider(normalizedSelectedDay)
            .overrideWith((ref) => selectedDayOverview),
        burnWeekRunControllerProvider.overrideWith(
          () => _FakeBurnWeekRunController(
            runState,
            onRestartRunFrom: onRestartRunFrom,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DiaryBalanceCard(selectedDay: normalizedSelectedDay),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  if (showDetails) {
    await tester.tap(find.byKey(DiaryBudgetCardKeys.detailsChip));
    await tester.pumpAndSettle();
  }
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  required DateTime weekStartDate,
  required List<double> dayTotals,
  double goalKcal = 2000,
  double? baseGoalKcal,
  double todayFlexibleGoalKcal = 2000,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  bool isPauseDay = false,
  double? previousDayCarryoverKcal,
  bool isPreviousDayClosed = false,
}) {
  final normalizedSelectedDay = normalizeLocalDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: addLocalDays(normalizedSelectedDay, -offset),
        totalKcal: dayTotals[6 - offset],
        goalKcal: goalKcal,
        baseGoalKcal: baseGoalKcal,
        entryCount: dayTotals[6 - offset] > 0 ? 1 : 0,
        isPauseDay: offset == 0 && isPauseDay,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(0, (sum, day) => sum + day.goalKcal);
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate: normalizeLocalDay(weekStartDate),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
    previousDayCarryoverKcal: previousDayCarryoverKcal,
    isPreviousDayClosed: isPreviousDayClosed,
  );
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  new(this.initialState, {this.onRestartRunFrom});

  final BurnWeekRunState initialState;
  final ValueChanged<DateTime>? onRestartRunFrom;
  @override
  Future<BurnWeekRunState> build() async => initialState;

  @override
  Future<bool> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    onRestartRunFrom?.call(weekStartDate);
    return true;
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

/// Today, 2026-04-27 at noon, with 800 kcal eaten of 2,000.
Future<void> _pumpToday(
  WidgetTester tester, {
  bool showDetails = false,
  bool paceMarkerOn = false,
}) {
  final day = DateTime(2026, 4, 27);
  return _pumpBalanceCard(
    tester,
    now: DateTime(2026, 4, 27, 12),
    selectedDay: day,
    weekStartDate: day,
    dayTotals: const [0, 0, 0, 0, 0, 0, 800],
    runState: const BurnWeekRunState.initial().copyWith(
      currentWeekStartDayKey: localDayKey(day),
    ),
    baseGoalKcal: 2000,
    showDetails: showDetails,
    paceMarkerOn: paceMarkerOn,
  );
}

/// Tomorrow, 2026-04-27, seen on Sunday evening with 900 kcal planned and a
/// carryover of 218 kcal per day once Sunday is closed.
Future<void> _pumpTomorrow(
  WidgetTester tester, {
  required bool isPreviousDayClosed,
  bool showDetails = false,
  List<CalorieEntry> plans = const [],
  bool paceMarkerOn = false,
}) {
  final day = DateTime(2026, 4, 27);
  return _pumpBalanceCard(
    tester,
    now: DateTime(2026, 4, 26, 20),
    selectedDay: day,
    weekStartDate: addLocalDays(day, -3),
    dayTotals: const [0, 0, 0, 0, 0, 0, 900],
    runState: const BurnWeekRunState.initial(),
    todayFlexibleGoalKcal: isPreviousDayClosed ? 2218 : 2000,
    previousDayCarryoverKcal: 218,
    isPreviousDayClosed: isPreviousDayClosed,
    showDetails: showDetails,
    plans: plans,
    paceMarkerOn: paceMarkerOn,
  );
}

String _textOf(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(find.byKey(key));
  return text.data ?? text.textSpan!.toPlainText();
}

final _breakfastPlan = CalorieEntry.create(
  id: 'plan-breakfast',
  userId: 'user-1',
  name: 'Brötchen',
  mealType: MealType.breakfast,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 300,
  per100Protein: 10,
  per100Carbs: 50,
  per100Fat: 5,
  loggedAt: DateTime(2026, 4, 27, 8),
  createdAt: DateTime(2026, 4, 26, 20),
  updatedAt: DateTime(2026, 4, 26, 20),
);

ClosedDayRepository _closedDayRepository(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DiaryBalanceCard)))
        .read(closedDayRepositoryProvider);
