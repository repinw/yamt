import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show
        DiaryWeeklyCheckInActions,
        DiaryWeeklyCheckInData,
        diaryCalorieGoalSettingsProvider,
        diaryWeeklyCheckInActionsProvider,
        diaryWeeklyCheckInDataProvider;
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_page.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_weekly_balance_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';
import '../support/diary_dashboard_test_support.dart';

DiaryWeeklyCheckInData _weeklyCheckInData = _emptyWeeklyCheckInCheckInData();

void _setWeeklyCheckInData(
  ProviderContainer container,
  DiaryWeeklyCheckInData data,
) {
  _weeklyCheckInData = data;
  container.invalidate(diaryWeeklyCheckInDataProvider);
}

class _MockUser extends Mock implements User {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository({
    this.state = const BurnWeekRunState.initial(),
  });

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    this.state = state;
    return true;
  }
}

class _TestDiaryCalendarController extends DiaryCalendarController {
  _TestDiaryCalendarController(this.day);

  final DateTime day;

  @override
  DiaryCalendarState build() {
    final normalizedDay = normalizeDiaryDay(day);
    return DiaryCalendarState(
      today: normalizedDay,
      selectedDay: normalizedDay,
      todayRequest: 0,
    );
  }
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
  inventoryBackedCalorieEntrySaveFlow,
])
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsOneWidget);
  });

  testWidgets('does not warm quick-eat inventory providers on diary open', (
    tester,
  ) async {
    var inventoryBuildCount = 0;
    var preparedMealsBuildCount = 0;
    final providerObserver = _RecordingProviderObserver();

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      providerObservers: [providerObserver],
      onInventoryBuild: () {
        inventoryBuildCount += 1;
      },
      onPreparedMealsBuild: () {
        preparedMealsBuildCount += 1;
      },
    );

    expect(inventoryBuildCount, 0);
    expect(preparedMealsBuildCount, 0);
    expect(providerObserver.calorieEntryDeleteFlowAddCount, 0);
  });

  test('diary warmup follows today without warming heavy providers', () async {
    final firstDay = DateTime(2026, 4, 27);
    final secondDay = DateTime(2026, 4, 28);
    final selectedDay = DateTime(2026, 4, 24);
    var now = firstDay;
    var firstBalanceBuilds = 0;
    var secondBalanceBuilds = 0;
    var selectedBalanceBuilds = 0;
    var firstMealsBuilds = 0;
    var secondMealsBuilds = 0;
    var selectedMealsBuilds = 0;

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
        diaryCalendarNowProvider.overrideWithValue(() => now),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          _FakeBurnWeekRunStateRepository(),
        ),
        inventoryItemsControllerProvider.overrideWith(
          _StaticInventoryItemsController.new,
        ),
        preparedMealsControllerProvider.overrideWith(
          _StaticPreparedMealsController.new,
        ),
        diaryBalanceSourceProvider(firstDay).overrideWith((ref) {
          firstBalanceBuilds += 1;
          return Completer<DiaryBalanceSource>().future;
        }),
        diaryBalanceSourceProvider(secondDay).overrideWith((ref) {
          secondBalanceBuilds += 1;
          return Completer<DiaryBalanceSource>().future;
        }),
        diaryBalanceSourceProvider(selectedDay).overrideWith((ref) {
          selectedBalanceBuilds += 1;
          return Completer<DiaryBalanceSource>().future;
        }),
        diaryMealSectionsProvider(firstDay).overrideWith((ref) {
          firstMealsBuilds += 1;
          return const [];
        }),
        diaryMealSectionsProvider(secondDay).overrideWith((ref) {
          secondMealsBuilds += 1;
          return const [];
        }),
        diaryMealSectionsProvider(selectedDay).overrideWith((ref) {
          selectedMealsBuilds += 1;
          return const [];
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

    expect(firstBalanceBuilds, 0);
    expect(firstMealsBuilds, 0);
    expect(selectedBalanceBuilds, 0);
    expect(selectedMealsBuilds, 0);

    container
        .read(diaryCalendarControllerProvider.notifier)
        .selectDay(selectedDay);
    await Future<void>.delayed(Duration.zero);

    expect(selectedBalanceBuilds, 0);
    expect(selectedMealsBuilds, 0);

    now = secondDay;
    container.read(diaryCalendarControllerProvider.notifier).refreshToday();
    await Future<void>.delayed(Duration.zero);

    expect(secondBalanceBuilds, 0);
    expect(secondMealsBuilds, 0);
  });

  testWidgets('loads weekly check-in section data immediately on first paint', (
    tester,
  ) async {
    var checkInBuildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diaryCalorieGoalSettingsProvider.overrideWith(
            (ref) async => const CalorieGoalSettings.empty(),
          ),
          diaryWeeklyCheckInActionsProvider.overrideWithValue(
            _noopWeeklyCheckInActions(),
          ),
          diaryWeeklyCheckInDataProvider.overrideWith((ref) {
            checkInBuildCount += 1;
            return _weeklyCheckInCheckInData(
              windowStartDate: DateTime(2026, 4, 20),
              shouldAutoOpen: false,
            );
          }),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsOneWidget);
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
    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsNothing);

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryWeeklyCheckInCardKeys.continueButton),
    );
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
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
        diaryWeeklyCheckInActionsProvider.overrideWithValue(
          DiaryWeeklyCheckInActions(
            syncLearnedTdeeCache: (_) async {},
            applyWeeklyCheckIn: (_) async => true,
            showWeeklyCheckInAgain: (_) async {
              _setWeeklyCheckInData(container, reopenedCheckIn);
              return true;
            },
            setSkippedIntakeDay:
                ({
                  required selectedDay,
                  required isSkipped,
                }) async => true,
            refreshCheckInData: () {},
          ),
        ),
      ],
    );

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton),
      findsOneWidget,
    );
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsNothing);

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.showAgainButton));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 21 - Apr 27'), findsOneWidget);
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInDialogKeys.trackMissingWeightButton),
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
        days: [
          _weeklyCheckInWindowDay(selectedDay),
        ],
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 13 - Apr 19'), findsOneWidget);

    _setWeeklyCheckInData(
      container,
      _weeklyCheckInCheckInData(
        windowStartDate: DateTime(2026, 4, 20),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Apr 13 - Apr 19'), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsNothing);

    await tester.tap(find.byKey(DiaryWeeklyCheckInDialogKeys.laterButton));
    await _pumpFrames(tester, count: 12);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 20 - Apr 26'), findsOneWidget);
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInDialogKeys.applyButton));
    await _pumpFrames(tester, count: 4);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);

    saveCompleter.complete();
    await _pumpFrames(tester);
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

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInDialogKeys.applyButton));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsNothing);
    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsOneWidget);
    expect(find.text('Could not close the weekly check-in.'), findsOneWidget);
  });

  testWidgets('shows activity tracking widgets when Health is ready', (
    tester,
  ) async {
    const healthStatus = HealthConnectionStatus(
      platform: HealthPlatform.ios,
      healthConnectAvailability: HealthConnectAvailability.notApplicable,
      permissionState: HealthPermissionState.granted,
      historyAccess: HealthHistoryAccess.notApplicable,
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      healthConnectionService: FakeHealthConnectionService(healthStatus),
      healthDataByDay: {
        diaryDayKey(selectedDay): const DiaryHealthDayData(
          totalSteps: 4321,
          workouts: [],
        ),
      },
    );

    await tester.scrollUntilVisible(
      find.byType(DiaryActivityWeightSection),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpFrames(tester);

    expect(find.byType(DiaryWeeklyBalanceSummary), findsOneWidget);
    expect(find.text('STEPS'), findsOneWidget);
    expect(find.textContaining('4,321', findRichText: true), findsOneWidget);
  });

  testWidgets('shows weekly check-in success card for todays learned target', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final snapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: today.subtract(const Duration(days: 7)),
      windowEndDate: today.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.05,
      calculatedTrueTdeeKcal: 2200,
      averageActiveKcal: 250,
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

    expect(
      find.byKey(DiaryWeeklyCheckInCardKeys.successCard),
      findsOneWidget,
    );
    expect(find.textContaining('1,800 kcal'), findsOneWidget);
  });

  testWidgets('shows practice day message before tomorrow goal start', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final startDate = nextDiaryDay(today);

    await _pumpDiaryPage(
      tester,
      selectedDay: today,
      logRepository: FakeCalorieLogRepository(
        initialEntries: [
          _entry(
            id: 'practice-food',
            day: today,
            mealType: MealType.breakfast,
          ),
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
    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.text('Goal: 1,200 kcal'), findsOneWidget);
  });

  testWidgets('shows first diary intro with calculator data once', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      locale: const Locale('de'),
      appPreferences: preferences,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 59,
            heightCm: 162,
            ageYears: 24,
            activityLevel: 1.2,
            goalMode: CalorieGoalMode.lose,
            goalSpeedKgPerWeek: 0.5,
          ),
          effectiveDate: selectedDay,
        ),
      ),
    );

    expect(find.byKey(DiaryIntroDialogKeys.dialog), findsOneWidget);
    expect(find.text('Dein Startwert'), findsOneWidget);
    expect(find.textContaining('1.586 kcal'), findsOneWidget);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
    await _pumpFrames(tester);

    expect(find.text('Dein Ziel'), findsOneWidget);

    for (var index = 0; index < 4; index += 1) {
      await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
      await _pumpFrames(tester);
    }

    expect(find.text('Aktivitäten'), findsOneWidget);
    expect(find.textContaining('Kaum aktiv'), findsOneWidget);
    expect(find.textContaining('264 kcal'), findsOneWidget);
    await tester.tap(find.byKey(DiaryIntroDialogKeys.doneButton));
    await _pumpFrames(tester);

    expect(find.byKey(DiaryIntroDialogKeys.dialog), findsNothing);
    expect(DiaryIntroPreferences.isSeen(preferences), isTrue);
  });

  testWidgets('first diary intro can start Health connection', (tester) async {
    final healthService = FakeHealthConnectionService(
      const HealthConnectionStatus(
        platform: HealthPlatform.ios,
        healthConnectAvailability: HealthConnectAvailability.notApplicable,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notApplicable,
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      locale: const Locale('de'),
      healthConnectionService: healthService,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 59,
            heightCm: 162,
            ageYears: 24,
            activityLevel: 1.2,
            goalMode: CalorieGoalMode.lose,
            goalSpeedKgPerWeek: 0.5,
          ),
          effectiveDate: selectedDay,
        ),
      ),
    );

    for (var index = 0; index < 5; index += 1) {
      await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
      await _pumpFrames(tester);
    }

    expect(find.byKey(DiaryIntroDialogKeys.healthActionButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(DiaryIntroDialogKeys.healthActionButton),
        matching: find.text('Verbinden'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryIntroDialogKeys.healthActionButton));
    await _pumpFrames(tester);

    expect(healthService.requestAuthorizationCallCount, 1);
  });

  testWidgets('first diary intro can install Health Connect', (tester) async {
    final healthService = FakeHealthConnectionService(
      const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.notInstalled,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notApplicable,
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      locale: const Locale('de'),
      healthConnectionService: healthService,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
      overrides: [
        burnWeekLiveSyncProvider.overrideWith((ref) => null),
      ],
    );
    await _advanceIntroToActivityPage(tester);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.healthActionButton));
    await _pumpFrames(tester);

    expect(healthService.installHealthConnectCallCount, 1);
  });

  testWidgets('first diary intro can open Health permission settings', (
    tester,
  ) async {
    final healthService = FakeHealthConnectionService(
      const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
        errorMessage: healthActivityRecognitionPermissionErrorMessage,
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      locale: const Locale('de'),
      healthConnectionService: healthService,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
    );
    await _advanceIntroToActivityPage(tester);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.healthActionButton));
    await _pumpFrames(tester);

    expect(healthService.openAppPermissionSettingsCallCount, 1);
  });

  testWidgets('first diary intro opens Health Connect settings for errors', (
    tester,
  ) async {
    final healthService = FakeHealthConnectionService(
      const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
        errorMessage: 'Health Connect permission failed.',
      ),
    );

    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      locale: const Locale('de'),
      healthConnectionService: healthService,
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
    );
    await _advanceIntroToActivityPage(tester);

    await tester.tap(find.byKey(DiaryIntroDialogKeys.healthActionButton));
    await _pumpFrames(tester);

    expect(healthService.openHealthPermissionSettingsCallCount, 1);
  });

  testWidgets('does not show first diary intro after completion', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      appPreferences: MemoryAppPreferences(
        initialStrings: DiaryIntroPreferences.initialSeenStrings(),
      ),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
    );

    expect(find.byKey(DiaryIntroDialogKeys.dialog), findsNothing);
  });

  testWidgets('does not show first diary intro after TDEE was learned', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      appPreferences: MemoryAppPreferences(),
      burnWeekRunState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-04-27',
      ),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: _learnedTdeeGoalSettings(selectedDay),
      ),
    );

    expect(find.byKey(DiaryIntroDialogKeys.dialog), findsNothing);
    expect(find.byKey(DiaryIntroDialogKeys.replayButton), findsNothing);
  });

  testWidgets('shows intro replay button during first diary week', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      appPreferences: MemoryAppPreferences(
        initialStrings: DiaryIntroPreferences.initialSeenStrings(),
      ),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
      overrides: [
        burnWeekLiveSyncProvider.overrideWith((ref) => null),
      ],
    );

    await tester.scrollUntilVisible(
      find.byKey(DiaryIntroDialogKeys.replayButton),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(DiaryIntroDialogKeys.replayButton), findsOneWidget);

    await _tapDiaryCardAction(
      tester,
      find.byKey(DiaryIntroDialogKeys.replayButton),
    );
    await _pumpFrames(tester);

    expect(find.byKey(DiaryIntroDialogKeys.dialog), findsOneWidget);
    expect(find.text('Your starting point'), findsOneWidget);
  });

  testWidgets('hides intro replay button after first diary week', (
    tester,
  ) async {
    await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      appPreferences: MemoryAppPreferences(
        initialStrings: DiaryIntroPreferences.initialSeenStrings(),
      ),
      burnWeekRunState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-04-27',
        lastActiveDayKey: '2026-04-30',
        runWeekNumber: 2,
      ),
      settingsRepository: FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: const CalorieCalculatorProfile.defaults(),
          effectiveDate: selectedDay,
        ),
      ),
    );

    expect(find.byKey(DiaryIntroDialogKeys.replayButton), findsNothing);
  });

  testWidgets('refreshes calendar today when the app resumes', (tester) async {
    var now = selectedDay;
    final container = await _pumpDiaryPage(
      tester,
      selectedDay: selectedDay,
      overrides: [
        diaryCalendarNowProvider.overrideWithValue(() => now),
      ],
    );

    now = selectedDay.add(const Duration(days: 1, hours: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final state = container.read(diaryCalendarControllerProvider);
    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 28));
    expect(state.todayRequest, 1);
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
      overrides: [
        diaryCalendarNowProvider.overrideWithValue(() => now),
        calorieBalanceNowProvider.overrideWithValue(() => now),
      ],
    );

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsNothing);

    now = DateTime(2026, 4, 15, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpFrames(tester);

    expect(find.byKey(DiaryWeeklyCheckInDialogKeys.dialog), findsOneWidget);
    expect(find.text('Apr 8 - Apr 14'), findsOneWidget);
  });
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<ProviderContainer> _pumpDiaryPage(
  WidgetTester tester, {
  required DateTime selectedDay,
  Locale locale = const Locale('en'),
  DiaryWeeklyCheckInData? initialWeeklyCheckIn,
  DiaryWeeklyCheckInData? preloadedWeeklyCheckIn,
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
  HealthConnectionService? healthConnectionService,
  MemoryAppPreferences? appPreferences,
  BurnWeekRunState? burnWeekRunState,
  Map<String, DiaryHealthDayData> healthDataByDay =
      const <String, DiaryHealthDayData>{},
  VoidCallback? onInventoryBuild,
  VoidCallback? onPreparedMealsBuild,
  List<ProviderObserver> providerObservers = const [],
  List<Override> overrides = const [],
  bool overrideWeeklyCheckInProvider = true,
  bool includeHomeShellChrome = false,
  bool useGoRouter = false,
  int initialFrameCount = 8,
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
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseAuthProvider.overrideWithValue(auth),
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      diaryDayDashboardControllerProvider(
        normalizedSelectedDay,
      ).overrideWithValue(
        diaryDashboardLoadedStateForTest(
          selectedDay: normalizedSelectedDay,
          weekOverview: weekOverview,
          selectedDayEntries: selectedDayEntries,
          runState: burnWeekRunState ?? const BurnWeekRunState.initial(),
        ),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        _FakeBurnWeekRunStateRepository(
          state: burnWeekRunState ?? const BurnWeekRunState.initial(),
        ),
      ),
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(onBuild: onInventoryBuild),
      ),
      preparedMealsControllerProvider.overrideWith(
        () => _StaticPreparedMealsController(onBuild: onPreparedMealsBuild),
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
      diaryHealthServiceProvider.overrideWithValue(
        FakeDiaryHealthService(healthDataByDay),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService(const <HealthWeightSample>[]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository(<ManualHealthWeightEntry>[]),
      ),
      if (overrideWeeklyCheckInProvider)
        diaryWeeklyCheckInDataProvider.overrideWith(
          (ref) => _weeklyCheckInData,
        ),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await resolvedLogRepository.dispose();
    await resolvedSettingsRepository.dispose();
    container.dispose();
  });

  final diaryPage = Scaffold(
    body: DiaryPage(
      includeHomeShellChrome: includeHomeShellChrome,
    ),
  );
  final app = useGoRouter
      ? MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: diaryPage,
        );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: app,
    ),
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
  final totalGoalKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );

  return CalorieWeekOverview(
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
  int calorieEntryDeleteFlowAddCount = 0;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (context.provider == calorieEntryDeleteFlowProvider) {
      calorieEntryDeleteFlowAddCount += 1;
    }
  }
}

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController({this.onBuild});

  final VoidCallback? onBuild;

  @override
  FutureOr<List<InventoryItem>> build() async {
    onBuild?.call();
    return const <InventoryItem>[];
  }
}

class _StaticPreparedMealsController extends PreparedMealsController {
  _StaticPreparedMealsController({this.onBuild});

  final VoidCallback? onBuild;

  @override
  FutureOr<List<PreparedMeal>> build() async {
    onBuild?.call();
    return const <PreparedMeal>[];
  }
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 8}) async {
  for (var index = 0; index < count; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _advanceIntroToActivityPage(WidgetTester tester) async {
  for (var index = 0; index < 5; index += 1) {
    await tester.tap(find.byKey(DiaryIntroDialogKeys.nextButton));
    await _pumpFrames(tester);
  }
}

DiaryWeeklyCheckInData _emptyWeeklyCheckInCheckInData() {
  return const DiaryWeeklyCheckInData(
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

DiaryWeeklyCheckInActions _noopWeeklyCheckInActions() {
  return DiaryWeeklyCheckInActions(
    syncLearnedTdeeCache: (_) async {},
    applyWeeklyCheckIn: (_) async => true,
    showWeeklyCheckInAgain: (_) async => true,
    setSkippedIntakeDay:
        ({
          required selectedDay,
          required isSkipped,
        }) async => true,
    refreshCheckInData: () {},
  );
}

DiaryWeeklyCheckInData _weeklyCheckInCheckInData({
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
  return DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: pending,
    shouldAutoOpen: shouldAutoOpen,
    days: days,
    calculation: const CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: -0.05,
      averageIntakeKcal: 2100,
      measuredTrueTdeeKcal: 2450,
      calculatedTrueTdeeKcal: 2400,
      newGoalKcal: 2200,
      lastWeekAverageActiveKcal: 250,
      todayActiveKcal: 300,
      activityDeltaKcal: 50,
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
    isHeartDay: false,
    activeKcal: 0,
    weightKg: null,
  );
}

CalorieGoalSettings _learnedTdeeGoalSettings(DateTime effectiveDate) {
  const profile = CalorieCalculatorProfile.defaults();
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1800,
    calculatorProfile: profile,
    effectiveDate: effectiveDate.subtract(const Duration(days: 8)),
    source: CalorieGoalSource.calculator,
  ).applyGoalChange(
    changedAt: effectiveDate.subtract(const Duration(days: 1)),
    dailyKcalGoal: 1800,
    calculatorProfile: profile,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: effectiveDate.subtract(const Duration(days: 8)),
      windowEndDate: effectiveDate.subtract(const Duration(days: 2)),
      trendWeightChangePerDay: -0.05,
      calculatedTrueTdeeKcal: 2100,
      averageActiveKcal: 120,
      lowConfidence: false,
    ),
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
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
