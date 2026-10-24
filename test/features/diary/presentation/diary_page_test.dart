import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_weight_missing_prompt_section.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_plan_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/diary/application/'
    'diary_day_dashboard_live_data_provider.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_weekly_checkin_sheet_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_day_type_toggle.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_choice_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/inventory/application/inventory_entry_delete_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';
import '../../../helpers/home_shell_test_scope.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';
import '../support/diary_dashboard_test_support.dart';

CalorieWeeklyCheckInData _weeklyCheckInData = _emptyWeeklyCheckInCheckInData();

void _setWeeklyCheckInData(
  ProviderContainer container,
  CalorieWeeklyCheckInData data,
) {
  _weeklyCheckInData = data;
  container.invalidate(calorieWeeklyCheckInDataProvider);
}

class _MockUser extends Mock implements User;

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new({this.state = const BurnWeekRunState.initial()});

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

/// Starts the calendar on [day], which may lie apart from today.
class _TestDiaryCalendarController extends DiaryCalendarController {
  new(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    final isFirstBuild = stateOrNull == null;
    final calendar = super.build();
    return isFirstBuild
        ? calendar.copyWith(selectedDay: normalizeDiaryDay(day))
        : calendar;
  }
}

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('auto-opens weekly check-in dialog', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 20 – APR 26'), findsOneWidget);
  });

  testWidgets('does not warm quick-eat inventory providers on diary open', (
    tester,
  ) async {
    final providerObserver = _RecordingProviderObserver();

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      providerObservers: [providerObserver],
    );

    expect(providerObserver.diaryQuickEatInventoryAddCount, 0);
    expect(providerObserver.entryDeleteServiceAddCount, 0);
  });

  testWidgets('shows day type toggle while diary dashboard refreshes', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      burnWeekRunState: const BurnWeekRunState.initial().copyWith(
        runWeekNumber: 2,
      ),
      dashboardState: const DiaryDayDashboardState(
        data: null,
        isFromCache: false,
        isRefreshing: true,
        error: null,
      ),
      body: const HomeShellTestScope(
        child: DiaryPage(includeHomeShellChrome: true),
      ),
    );

    expect(find.byKey(DiaryDayTypeToggle.buttonKey), findsOneWidget);
  });

  testWidgets('tapping the day type tool opens the day types in the panel', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      body: const HomeShellTestScope(
        child: DiaryPage(includeHomeShellChrome: true),
      ),
    );

    await tester.tap(find.byKey(DiaryDayTypeToggle.buttonKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsOneWidget);
    expect(find.text('DAY TYPE'), findsOneWidget);
    expect(find.text('Training day'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Pause day'), findsOneWidget);
  });

  test('diary warmup follows today without warming heavy providers', () async {
    final firstDay = DateTime(2026, 4, 27);
    final secondDay = DateTime(2026, 4, 28);
    final selectedDay = DateTime(2026, 4, 24);
    var now = firstDay;
    var firstDashboardBuilds = 0;
    var secondDashboardBuilds = 0;
    var selectedDashboardBuilds = 0;

    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: firstDay,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          _FakeBurnWeekRunStateRepository(),
        ),
        diaryDayDashboardLiveDataProvider(firstDay).overrideWith((ref) {
          firstDashboardBuilds += 1;
          return Completer<DiaryDayDashboardLiveData>().future;
        }),
        diaryDayDashboardLiveDataProvider(secondDay).overrideWith((ref) {
          secondDashboardBuilds += 1;
          return Completer<DiaryDayDashboardLiveData>().future;
        }),
        diaryDayDashboardLiveDataProvider(selectedDay).overrideWith((ref) {
          selectedDashboardBuilds += 1;
          return Completer<DiaryDayDashboardLiveData>().future;
        }),
      ],
    );
    addTearDown(() async {
      await logRepository.dispose();
      await settingsRepository.dispose();
      container.dispose();
    });

    final subscription = container.listen<void>(
      diaryProviderWarmupProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect(firstDashboardBuilds, 0);
    expect(selectedDashboardBuilds, 0);

    container
        .read(diaryCalendarControllerProvider.notifier)
        .selectDay(selectedDay);
    await Future<void>.delayed(Duration.zero);

    expect(selectedDashboardBuilds, 0);

    now = secondDay;
    container.read(diaryTodayProvider.notifier).refresh();
    await Future<void>.delayed(Duration.zero);

    expect(secondDashboardBuilds, 0);
  });

  testWidgets('loads weekly check-in section data immediately on first paint', (
    tester,
  ) async {
    var checkInBuildCount = 0;
    final emptySettings = FakeCalorieSettingsRepository();
    addTearDown(emptySettings.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(emptySettings),
          calorieWeeklyCheckInControllerProvider.overrideWith(
            _FakeWeeklyCheckInController.new,
          ),
          calorieWeeklyCheckInDataProvider.overrideWith((ref) {
            checkInBuildCount += 1;
            return _weeklyCheckInCheckInData(
              windowStartDate: DateTime(2026, 4, 20),
              shouldAutoOpen: false,
            );
          }),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DiaryWeeklyCheckInSection(selectedDay: selectedDay),
          ),
        ),
      ),
    );

    // After the initial paint, the post-frame callback fires immediately.
    await tester.pump();

    expect(checkInBuildCount, 1);
  });

  testWidgets('auto-opens already loaded weekly check-in dialog', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      preloadedWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 20 – APR 26'), findsOneWidget);
  });

  testWidgets('weekly check-in hint continue opens dialog', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      useGoRouter: true,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 21),
        shouldAutoOpen: false,
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsOneWidget);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryWeeklyCheckInCardKeys.continueButton),
    );
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
  });

  testWidgets('show-again button reopens dismissed weekly check-in', (
    tester,
  ) async {
    late ProviderContainer container;
    final windowStartDate = DateTime(2026, 4, 21);
    final dismissedCheckIn = _weeklyCheckInCheckInData(
      windowStartDate: windowStartDate,
      shouldAutoOpen: false,
      dismissedAt: DateTime(2026, 4, 28, 9),
    );
    final reopenedCheckIn = _weeklyCheckInCheckInData(
      windowStartDate: windowStartDate,
      shouldAutoOpen: false,
    );

    container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      initialWeeklyCheckIn: dismissedCheckIn,
      overrides: [
        calorieWeeklyCheckInControllerProvider.overrideWith(
          () => _FakeWeeklyCheckInController(
            onShowAgain: (_) {
              _setWeeklyCheckInData(container, reopenedCheckIn);
            },
          ),
        ),
      ],
    );

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton),
      findsOneWidget,
    );
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 21 – APR 27'), findsOneWidget);
  });

  testWidgets('weekly check-in hint opens missing weight day', (tester) async {
    final missingWeightDay = DateTime(2026, 4, 21);

    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      useGoRouter: true,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: missingWeightDay,
        shouldAutoOpen: false,
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
        missingWeightDays: [missingWeightDay],
      ),
    );

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.trackMissingWeightButton),
      findsOneWidget,
    );

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryWeeklyCheckInCardKeys.trackMissingWeightButton),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      missingWeightDay,
    );
    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsOneWidget);
  });

  testWidgets('weekly check-in dialog opens missing weight day', (
    tester,
  ) async {
    final missingWeightDay = DateTime(2026, 4, 27);

    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      useGoRouter: true,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 21),
        shouldAutoOpen: false,
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
        missingWeightDays: [missingWeightDay],
      ),
    );

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryWeeklyCheckInCardKeys.continueButton),
    );
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInSheetKeys.trackMissingWeightButton),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      missingWeightDay,
    );
    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsOneWidget);
  });

  testWidgets('weekly check-in skip day failure shows snackbar', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    )..saveShouldFail = true;

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 21),
        shouldAutoOpen: false,
        days: [_weeklyCheckInWindowDay(selectedDay)],
      ),
    );

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.skipDayButton),
      findsOneWidget,
    );

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryWeeklyCheckInCardKeys.skipDayButton),
    );
    await _pumpFrames(tester);

    expect(find.text('Could not save calorie goal.'), findsOneWidget);
  });

  testWidgets('defers a second weekly check-in while a dialog is open', (
    tester,
  ) async {
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 13),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 13 – APR 19'), findsOneWidget);

    _setWeeklyCheckInData(
      container,
      _weeklyCheckInCheckInData(windowStartDate: DateTime(2026, 4, 20)),
    );
    await _pumpFrames(tester);

    expect(find.textContaining('APR 13 – APR 19'), findsOneWidget);
    expect(find.textContaining('APR 20 – APR 26'), findsNothing);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton));
    await _pumpFrames(tester, count: 12);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 20 – APR 26'), findsOneWidget);
  });

  testWidgets('hides weekly check-in hint immediately while apply saves', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    )..onSaveSettings = (_) => saveCompleter.future;

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);

    await _finishWeeklyCheckIn(tester, keepPrevious: false);
    await _pumpFrames(tester, count: 4);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);

    saveCompleter.complete();
    await _pumpFrames(tester);
    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton),
      findsNothing,
    );
  });

  testWidgets('shows weekly check-in hint again when apply fails', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    )..saveShouldFail = true;

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);

    await _finishWeeklyCheckIn(tester, keepPrevious: false);
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsOneWidget);
    expect(find.text('Could not close the weekly check-in.'), findsOneWidget);
  });

  testWidgets('hides weekly check-in hint and dialog when reject succeeds', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice),
      findsOneWidget,
    );

    await _finishWeeklyCheckIn(tester, keepPrevious: true);
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);
    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton),
      findsNothing,
    );

    final currentSettings = await settingsRepository.readSettings();
    expect(
      currentSettings.goalHistory.last.weeklyCheckInSnapshot?.isRejected,
      isTrue,
    );
    // The base goal stays; the planned training days only split it.
    expect(currentSettings.baseGoalKcalForDay(selectedDay), 2200);
  });

  testWidgets('shows weekly check-in hint again when reject fails', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    )..saveShouldFail = true;

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);

    await _finishWeeklyCheckIn(tester, keepPrevious: true);
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsOneWidget);
    expect(find.text('Could not reject the weekly check-in.'), findsOneWidget);
  });

  testWidgets(
    'back from the goal sheet reopens the check-in with its choices',
    (tester) async {
      final windowStartDate = DateTime(2026, 4, 20);
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        initialWeeklyCheckIn: _weeklyCheckInCheckInData(
          windowStartDate: windowStartDate,
        ),
      );
      DiaryWeeklyCheckInSheetState sheetState() => container
          .read(
            diaryWeeklyCheckInSheetControllerProvider(
              windowStart: windowStartDate,
            ),
          )
          .requireValue!;

      await _tapCheckInSheet(
        tester,
        DiaryWeeklyCheckInSheetKeys.keepPreviousChoice,
      );
      await _tapCheckInSheet(tester, DiaryWeeklyCheckInSheetKeys.nextButton);
      await _tapCheckInSheet(
        tester,
        DiaryWeeklyCheckInSheetKeys.trainingDay(1),
      );
      await _tapCheckInSheet(tester, DiaryWeeklyCheckInSheetKeys.backButton);
      final choices = sheetState();
      expect(choices.trainingDays, hasLength(4));

      await _tapCheckInSheet(
        tester,
        DiaryWeeklyCheckInSheetKeys.changeGoalButton,
      );
      expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
      expect(
        find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
      );
      await _pumpFrames(tester);

      expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
      expect(
        find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
        findsNothing,
      );
      expect(
        tester
            .widget<DiaryWeeklyCheckInChoiceTile>(
              find.byKey(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice),
            )
            .isSelected,
        isTrue,
      );
      expect(sheetState().step, DiaryWeeklyCheckInStep.review);
      expect(sheetState().useMeasured, isFalse);
      expect(sheetState().trainingDays, choices.trainingDays);
    },
  );

  testWidgets('leaving the goal sheet without a goal keeps the check-in open', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: selectedDay.subtract(const Duration(days: 14)),
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );

    await _tapCheckInSheet(
      tester,
      DiaryWeeklyCheckInSheetKeys.changeGoalButton,
    );
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.cancelButton));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);

    await _tapCheckInSheet(
      tester,
      DiaryWeeklyCheckInSheetKeys.changeGoalButton,
    );
    await tester.tapAt(const Offset(5, 5));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsNothing,
    );
    final settings = await settingsRepository.readSettings();
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalHistory.single.weeklyCheckInSnapshot, isNull);
  });

  testWidgets('saving a new goal from the check-in does not reopen it', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final goalStartDate = today.subtract(const Duration(days: 14));
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: goalStartDate,
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: goalStartDate,
          windowEndDate: goalStartDate.add(const Duration(days: 6)),
          trendWeightChangePerDay: -0.05,
          calculatedTdeeKcal: 2400,
          lowConfidence: false,
        ),
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      settingsRepository: settingsRepository,
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: today.subtract(const Duration(days: 7)),
      ),
    );

    await _tapCheckInSheet(
      tester,
      DiaryWeeklyCheckInSheetKeys.changeGoalButton,
    );
    await _tapCheckInSheet(tester, CalorieLearnedTdeeSheetKeys.saveButton);
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await _pumpFrames(tester);

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);
    final newGoal = (await settingsRepository.readSettings()).latestGoalEntry;
    expect(newGoal?.source, CalorieGoalSource.calculator);
    expect(newGoal?.effectiveDate, today);
  });

  testWidgets(
    'diary no longer shows weekly progress or check-in while loading',
    (tester) async {
      await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        dashboardState: const DiaryDayDashboardState(
          data: null,
          isFromCache: false,
          isRefreshing: true,
          error: null,
        ),
        initialFrameCount: 0,
      );

      expect(find.byType(DiaryWeeklyCheckInSection), findsNothing);
    },
  );

  testWidgets('shows the missing-weight prompt on today without weight', (
    tester,
  ) async {
    await _pumpDiaryPage(tester, selectedDay: selectedDay);

    expect(find.byType(DiaryWeightMissingPromptSection), findsOneWidget);
    expect(find.byType(DiaryWeightMissingPromptCard), findsOneWidget);
  });

  testWidgets('hides the missing-weight prompt while the check-in asks for '
      'weight', (tester) async {
    final missingWeightDay = DateTime(2026, 4, 21);

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      preloadedWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: missingWeightDay,
        shouldAutoOpen: false,
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
        missingWeightDays: [missingWeightDay],
      ),
    );

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.trackMissingWeightButton),
      findsOneWidget,
    );
    expect(find.byType(DiaryWeightMissingPromptSection), findsNothing);
  });

  testWidgets('hides the missing-weight prompt on past days', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      today: selectedDay.add(const Duration(days: 1)),
    );

    expect(find.byType(DiaryWeightMissingPromptSection), findsNothing);
  });

  testWidgets('hides the weekly check-in on future days', (tester) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      today: selectedDay.subtract(const Duration(days: 1)),
      initialWeeklyCheckIn: _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 21),
        shouldAutoOpen: false,
      ),
    );

    expect(find.byType(DiaryWeeklyCheckInSection), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);
  });

  testWidgets('shows weekly check-in success card for todays learned target', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final snapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: today.subtract(const Duration(days: 7)),
      windowEndDate: today.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.05,
      calculatedTdeeKcal: 2200,
      lowConfidence: false,
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1800,
          calculatorProfile: null,
          effectiveDate: today,
          source: CalorieGoalSource.weeklyCheckIn,
          weeklyCheckInSnapshot: snapshot,
        ),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsOneWidget);
    expect(
      find.text('Target updated from weekly check-in: 1,800 kcal.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the check-in success card only on today', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpDiaryPage(
      tester,
      selectedDay: previousDiaryDay(today),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: _weeklyCheckInGoalSettings(today),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsNothing);
  });

  testWidgets('closing the check-in success card keeps it closed', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: _weeklyCheckInGoalSettings(today),
      ),
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.successCardClose));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsNothing);
  });

  testWidgets('redo on the check-in success card reopens its window', (
    tester,
  ) async {
    late ProviderContainer container;
    final today = normalizeDiaryDay(DateTime.now());
    final windowStartDate = today.subtract(const Duration(days: 7));
    PendingCalorieGoalWeeklyCheckIn? reopened;

    container = await _pumpDiaryPage(
      tester,
      selectedDay: today,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: _weeklyCheckInGoalSettings(today),
      ),
      overrides: [
        calorieWeeklyCheckInControllerProvider.overrideWith(
          () => _FakeWeeklyCheckInController(
            onShowAgain: (checkIn) {
              reopened = checkIn;
              _setWeeklyCheckInData(
                container,
                _weeklyCheckInCheckInData(
                  windowStartDate: windowStartDate,
                  shouldAutoOpen: false,
                ),
              );
            },
          ),
        ),
      ],
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.successCardRedo));
    await _pumpFrames(tester);

    expect(reopened?.windowStartDate, windowStartDate);
    expect(reopened?.windowEndDate, previousDiaryDay(today));
    expect(reopened?.isDismissed, isFalse);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
  });

  testWidgets('offers no redo once the check-in inputs changed', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: _weeklyCheckInGoalSettings(today)
            .invalidateWeeklyCheckInSnapshotsFromDay(
              day: previousDiaryDay(today),
              invalidatedAt: today,
            ),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.successCard), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.successCardRedo),
      findsNothing,
    );
  });

  testWidgets('shows a practice day before tomorrow goal start', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final startDate = nextDiaryDay(today);

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      logRepository: FakeCalorieLogRepository(
        initialEntries: [
          _entry(id: 'practice-food', day: today, mealType: MealType.breakfast),
        ],
      ),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: null,
          effectiveDate: startDate,
          countingStartDate: startDate,
        ),
      ),
    );

    expect(find.byKey(DiaryBalanceCardKeys.practiceDay), findsOneWidget);
    expect(find.textContaining('Practice day · counts from'), findsOneWidget);
    expect(find.byKey(DiaryBalanceCardKeys.dailyProgressTrack), findsOneWidget);
  });

  testWidgets('swiping the page selects the neighbouring day', (tester) async {
    final container = await _pumpDiaryPage(tester, selectedDay: selectedDay);
    DateTime currentDay() =>
        container.read(diaryCalendarControllerProvider).selectedDay;

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    // The page spring needs a while to come to rest.
    await _pumpFrames(tester, count: 20);
    expect(currentDay(), DateTime(2026, 4, 28));
    expect(
      tester.widget<DiaryDayView>(find.byType(DiaryDayView)).day,
      DateTime(2026, 4, 28),
    );

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await _pumpFrames(tester, count: 20);
    expect(currentDay(), selectedDay);
  });

  group('a plan that loads after the first frames keeps today (#817)', () {
    // On a cold start the plan arrives after the first frames, and it started
    // longer ago than the diary looks ahead.
    final planStart = DateTime(2026, 4, 6);
    Future<void> loadPlan(FakeCalorieSettingsRepository repository) =>
        repository.saveSettings(
          CalorieGoalSettings.single(
            dailyKcalGoal: 2200,
            calculatorProfile: null,
            effectiveDate: planStart,
          ),
        );
    void expectToday(
      WidgetTester tester,
      ProviderContainer container, {
      DateTime? day,
    }) {
      final shownDay = day ?? selectedDay;
      final bounds = container.read(diaryCalendarBoundsProvider);
      expect(bounds.earliestDay, planStart);
      expect(
        container.read(diaryCalendarControllerProvider).selectedDay,
        shownDay,
      );
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        bounds.indexOf(shownDay),
      );
    }

    testWidgets('while the diary shows', (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        settingsRepository: settingsRepository,
      );

      await loadPlan(settingsRepository);
      await _pumpFrames(tester, count: 20);

      expectToday(tester, container);
    });

    testWidgets('while another tab hides the diary', (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        settingsRepository: settingsRepository,
        // How the home shell keeps the tabs it does not show.
        body: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, isVisible, child) => Offstage(
            offstage: !isVisible,
            child: TickerMode(enabled: isVisible, child: child!),
          ),
          child: const DiaryPage(),
        ),
      );

      visible.value = false;
      await _pumpFrames(tester, count: 3);
      await loadPlan(settingsRepository);
      await _pumpFrames(tester, count: 5);
      visible.value = true;
      await _pumpFrames(tester, count: 20);

      expectToday(tester, container);
    });

    testWidgets('while a page covers the diary', (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        settingsRepository: settingsRepository,
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator))
        ..push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await _pumpFrames(tester, count: 10);
      await loadPlan(settingsRepository);
      await _pumpFrames(tester, count: 10);
      navigator.pop();
      await _pumpFrames(tester, count: 20);

      expectToday(tester, container);
    });

    testWidgets('during a swipe', (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        settingsRepository: settingsRepository,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await loadPlan(settingsRepository);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await _pumpFrames(tester, count: 20);

      expectToday(tester, container);
    });

    testWidgets('during a slide to the next day', (tester) async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final container = await _pumpDiaryPage(
        tester,
        selectedDay: selectedDay,
        settingsRepository: settingsRepository,
      );

      container.read(diaryCalendarControllerProvider.notifier).selectNextDay();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await loadPlan(settingsRepository);
      await _pumpFrames(tester, count: 20);

      expectToday(tester, container, day: DateTime(2026, 4, 28));
    });
  });

  testWidgets('a reset while hidden during a slide wins over the slide '
      '(#753)', (tester) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      body: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, isVisible, child) =>
            TickerMode(enabled: isVisible, child: child!),
        child: const DiaryPage(),
      ),
    );
    final calendar = container.read(diaryCalendarControllerProvider.notifier)
      ..selectNextDay();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The user leaves the tab mid-slide; the diary goes back to today after
    // that frame, as `diaryTabLeft` does.
    visible.value = false;
    await tester.pump();
    calendar.showToday();
    await _pumpFrames(tester, count: 3);
    visible.value = true;
    await _pumpFrames(tester);

    final bounds = container.read(diaryCalendarBoundsProvider);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(
      container.read(diaryCalendarControllerProvider).isSelectedToday,
      isTrue,
    );
    expect(pageView.controller!.page, bounds.indexOf(selectedDay));
  });

  testWidgets('selecting another day slides the pages to it', (tester) async {
    final container = await _pumpDiaryPage(tester, selectedDay: selectedDay);

    container.read(diaryCalendarControllerProvider.notifier).selectNextDay();
    await _pumpFrames(tester);

    final bounds = container.read(diaryCalendarBoundsProvider);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, bounds.indexOf(DateTime(2026, 4, 28)));
    expect(
      tester.widget<DiaryDayView>(find.byType(DiaryDayView)).day,
      DateTime(2026, 4, 28),
    );
  });

  testWidgets('refreshes calendar today when the app resumes', (tester) async {
    var now = selectedDay;
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      clock: () => now,
    );

    now = selectedDay.add(const Duration(days: 1, hours: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final state = container.read(diaryCalendarControllerProvider);
    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 28));
  });

  testWidgets('a longer absence opens today, a short one keeps the day '
      '(#753)', (tester) async {
    var now = selectedDay.add(const Duration(hours: 10));
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      clock: () => now,
    );
    final calendar = container.read(diaryCalendarControllerProvider.notifier);
    Future<void> leaveFor(Duration away) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      now = now.add(away);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    }

    calendar.selectPreviousDay();
    await leaveFor(const Duration(minutes: 1));
    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 26),
      reason: 'a camera photo or a permission prompt keeps the day',
    );

    await leaveFor(const Duration(minutes: 5));
    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      selectedDay,
    );

    // A short absence over midnight opens the new day.
    calendar.selectPreviousDay();
    now = DateTime(2026, 4, 27, 23, 58);
    await leaveFor(const Duration(minutes: 3));
    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 28),
    );
  });

  testWidgets('moves calendar today at midnight while the diary is open', (
    tester,
  ) async {
    var now = selectedDay.add(const Duration(hours: 23, minutes: 59));
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      clock: () => now,
    );

    now = selectedDay.add(const Duration(days: 1));
    await tester.pump(const Duration(minutes: 1));

    final state = container.read(diaryCalendarControllerProvider);
    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 28));
  });

  testWidgets('auto-opens weekly check-in after resume into due day', (
    tester,
  ) async {
    var now = DateTime(2026, 4, 14, 10);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 8),
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: DateTime(2026, 4, 14),
      settingsRepository: settingsRepository,
      overrideWeeklyCheckInProvider: false,
      clock: () => now,
    );

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsNothing);

    now = DateTime(2026, 4, 15, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(find.textContaining('APR 8 – APR 14'), findsOneWidget);
  });
}

/// Scrolls to the button of the check-in or goal sheet with [key] and taps it.
Future<void> _tapCheckInSheet(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await _pumpFrames(tester);
  await tester.tap(finder);
  await _pumpFrames(tester);
}

/// Walks the check-in sheet to its last step and starts the week.
Future<void> _finishWeeklyCheckIn(
  WidgetTester tester, {
  required bool keepPrevious,
}) async {
  if (keepPrevious) {
    final choice = find.byKey(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice);
    await tester.ensureVisible(choice);
    await _pumpFrames(tester);
    await tester.tap(choice);
    await _pumpFrames(tester);
  }
  for (var step = 0; step < 3; step++) {
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await _pumpFrames(tester);
  }
  await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
}

Future<ProviderContainer> _pumpDiaryPage(
  WidgetTester tester, {
  required DateTime selectedDay,
  DateTime? today,
  DateTime Function()? clock,
  Locale locale = const Locale('en'),
  CalorieWeeklyCheckInData? initialWeeklyCheckIn,
  CalorieWeeklyCheckInData? preloadedWeeklyCheckIn,
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
  HealthConnectionService? healthConnectionService,
  MemoryAppPreferences? appPreferences,
  BurnWeekRunState? burnWeekRunState,
  DiaryDayDashboardState? dashboardState,
  List<ProviderObserver> providerObservers = const [],
  List<Override> overrides = const [],
  bool overrideWeeklyCheckInProvider = true,
  bool includeHomeShellChrome = false,
  bool useGoRouter = false,
  int initialFrameCount = 8,
  Widget? body,
}) async {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ??
      FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: null,
          effectiveDate: selectedDay.subtract(const Duration(days: 14)),
        ),
      );
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final auth = _MockFirebaseAuth();

  _weeklyCheckInData =
      preloadedWeeklyCheckIn ?? _emptyWeeklyCheckInCheckInData();
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final settings = await resolvedSettingsRepository.readSettings();
  final selectedDayEntries = await resolvedLogRepository.readEntriesForDay(
    normalizedSelectedDay,
  );
  final weekOverview = _dashboardWeekOverviewForPageTest(
    selectedDay: normalizedSelectedDay,
    settings: settings,
    selectedDayEntries: selectedDayEntries,
  );

  final container = ProviderContainer(
    observers: providerObservers,
    overrides: [
      appPreferencesProvider.overrideWithValue(
        appPreferences ?? MemoryAppPreferences(),
      ),
      // The check-in plans and saves the run of this day.
      clockProvider.overrideWithValue(clock ?? () => today ?? selectedDay),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseAuthProvider.overrideWithValue(auth),
      userDataCipherProvider.overrideWithValue(testUserDataCipher),
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      diaryDayDashboardControllerProvider(normalizedSelectedDay).overrideWith(
        () => FakeDiaryDayDashboardController(
          dashboardState ??
              diaryDashboardLoadedStateForTest(
                selectedDay: normalizedSelectedDay,
                weekOverview: weekOverview,
                selectedDayEntries: selectedDayEntries,
                runState: burnWeekRunState ?? const BurnWeekRunState.initial(),
              ),
        ),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        _FakeBurnWeekRunStateRepository(
          state: burnWeekRunState ?? const BurnWeekRunState.initial(),
        ),
      ),
      diaryCalendarControllerProvider.overrideWith(
        () => _TestDiaryCalendarController(selectedDay),
      ),
      healthConnectionServiceProvider.overrideWithValue(
        healthConnectionService ??
            FakeHealthConnectionService(
              const HealthConnectionStatus.unsupported(),
            ),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService(const <HealthWeightSample>[]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository(<ManualHealthWeightEntry>[]),
      ),
      if (overrideWeeklyCheckInProvider)
        calorieWeeklyCheckInDataProvider.overrideWith(
          (ref) => _weeklyCheckInData,
        ),
      calorieWeeklyCheckInPlanProvider.overrideWith((ref) async {
        final checkInData = await ref.watch(
          calorieWeeklyCheckInDataProvider.future,
        );
        final pending = checkInData.pendingWeeklyCheckIn;
        return pending == null
            ? null
            : calorieWeeklyCheckInDemoPlan(
                today: pending.dueDate,
                macroSettings: const MacroGoalSettings(),
                profile: null,
              );
      }),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await resolvedLogRepository.dispose();
    await resolvedSettingsRepository.dispose();
    container.dispose();
  });

  final diaryPage = Scaffold(
    body: body ?? DiaryPage(includeHomeShellChrome: includeHomeShellChrome),
  );
  final app = useGoRouter
      ? MaterialApp.router(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: AppRoutes.homeCalories,
            routes: [
              GoRoute(
                path: AppRoutes.homeCalories,
                builder: (context, state) => diaryPage,
              ),
            ],
          ),
        )
      : MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: diaryPage,
        );

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: app),
  );
  if (initialFrameCount > 0) {
    await _pumpFrames(tester, count: initialFrameCount);
  }
  if (initialWeeklyCheckIn != null) {
    _setWeeklyCheckInData(container, initialWeeklyCheckIn);
    await _pumpFrames(tester);
  }
  return container;
}

CalorieWeekOverview _dashboardWeekOverviewForPageTest({
  required DateTime selectedDay,
  required CalorieGoalSettings settings,
  required List<CalorieEntry> selectedDayEntries,
}) {
  final dayTotal = selectedDayEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalKcal,
  );
  final nextGoalStartDate = settings.nextGoalStartAfterDay(selectedDay);
  final futureGoalKcal = nextGoalStartDate == null
      ? null
      : settings.goalKcalForDay(nextGoalStartDate);
  final goalStartsInFuture = nextGoalStartDate != null;
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: selectedDay.subtract(Duration(days: offset)),
        totalKcal: offset == 0 ? dayTotal : 0,
        goalKcal: settings.goalKcalForDay(
          selectedDay.subtract(Duration(days: offset)),
        ),
        entryCount: offset == 0 ? selectedDayEntries.length : 0,
      ),
  ];
  final totalGoalKcal = days.fold<double>(0, (sum, day) => sum + day.goalKcal);

  return CalorieWeekOverview(
    isPreviousDayClosed: false,
    days: days,
    totalConsumedKcal: dayTotal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - dayTotal,
    balanceStartDate: selectedDay.subtract(const Duration(days: 6)),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: settings.goalKcalForDay(selectedDay),
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
  );
}

Future<void> _tapDiaryCardAction(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump();
  }
  await tester.tap(finder.hitTestable());
}

final class _RecordingProviderObserver extends ProviderObserver {
  int entryDeleteServiceAddCount = 0;
  int diaryQuickEatInventoryAddCount = 0;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (context.provider == inventoryEntryDeleteServiceProvider) {
      entryDeleteServiceAddCount += 1;
    }
    if (context.provider == diaryQuickEatInventoryProvider) {
      diaryQuickEatInventoryAddCount += 1;
    }
  }
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 8}) async {
  for (var index = 0; index < count; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

CalorieWeeklyCheckInData _emptyWeeklyCheckInCheckInData() {
  return const CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: null,
    shouldAutoOpen: false,
    days: <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: <DateTime>[],
    missingWeightDays: <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

/// Answers the check-in actions without saving; [onShowAgain] sees the
/// reopened check-in.
class _FakeWeeklyCheckInController extends CalorieWeeklyCheckInController {
  new({this.onShowAgain});

  final void Function(PendingCalorieGoalWeeklyCheckIn pending)? onShowAgain;

  @override
  Future<bool> syncLearnedTdeeCache(
    CalorieWeeklyCheckInData checkInData,
  ) async => true;

  @override
  Future<bool> showPendingWeeklyCheckInAgain(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) async {
    onShowAgain?.call(pendingWeeklyCheckIn);
    return true;
  }
}

CalorieWeeklyCheckInData _weeklyCheckInCheckInData({
  required DateTime windowStartDate,
  bool shouldAutoOpen = true,
  DateTime? dismissedAt,
  CalorieWeeklyCheckInBlockedReason? blockedReason,
  List<DateTime> missingWeightDays = const <DateTime>[],
  List<CalorieWeeklyCheckInWindowDay> days =
      const <CalorieWeeklyCheckInWindowDay>[],
}) {
  final pending = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: windowStartDate,
    windowEndDate: windowStartDate.add(const Duration(days: 6)),
    dueDate: windowStartDate.add(const Duration(days: 7)),
    dismissedAt: dismissedAt,
  );
  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pending,
    shouldAutoOpen: shouldAutoOpen,
    days: days,
    calculation: const CalorieWeeklyCheckInCalculation(
      previousTdeeKcal: 2000,
      previousGoalKcal: 2000,
      trendWeightChangePerDay: -0.05,
      averageIntakeKcal: 2100,
      measuredTdeeKcal: 2450,
      calculatedTdeeKcal: 2400,
      newGoalKcal: 2200,
      dynamicGoalTodayKcal: 2250,
    ),
    blockedReason: blockedReason,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: missingWeightDays,
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

CalorieWeeklyCheckInWindowDay _weeklyCheckInWindowDay(DateTime day) {
  return CalorieWeeklyCheckInWindowDay(
    day: day,
    hasEntries: false,
    loggedIntakeKcal: 0,
    resolvedIntakeKcal: null,
    isSkippedIntakeDay: false,
    isPauseDay: false,
    weightKg: null,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    isQuickEntry: false,
    id: id,
    userId: 'user-1',
    name: 'Debug food',
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 12,
    per100Fat: 5,
    totalKcal: 100,
    totalProtein: 10,
    totalCarbs: 12,
    totalFat: 5,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieGoalSettings _weeklyCheckInGoalSettings(DateTime today) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1800,
    calculatorProfile: null,
    effectiveDate: today,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: today.subtract(const Duration(days: 7)),
      windowEndDate: today.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.05,
      calculatedTdeeKcal: 2200,
      lowConfidence: false,
    ),
  );
}
