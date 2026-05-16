import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

ProviderContainer _createContainer({
  required DateTime today,
  required CalorieGoalSettings settings,
  required DiaryHealthService diaryHealthService,
  HealthConnectionService? healthConnectionService,
  CalorieLogRepositoryContract? logRepository,
  HealthWeightService? healthWeightService,
  ManualHealthWeightRepository? manualWeightRepository,
}) {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  final overrides = [
    calorieBalanceNowProvider.overrideWith(
      (ref) =>
          () => today,
    ),
    calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    healthConnectionServiceProvider.overrideWith(
      (ref) =>
          healthConnectionService ??
          FakeHealthConnectionService(
            _readyStatus,
          ),
    ),
    diaryHealthServiceProvider.overrideWith((ref) => diaryHealthService),
  ];
  if (logRepository != null) {
    overrides.add(
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
    );
  }
  if (healthWeightService != null) {
    overrides.add(
      healthWeightServiceProvider.overrideWith((ref) => healthWeightService),
    );
  }
  if (manualWeightRepository != null) {
    overrides.add(
      manualHealthWeightRepositoryProvider.overrideWith(
        (ref) => manualWeightRepository,
      ),
    );
  }
  return ProviderContainer(
    overrides: overrides,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime loggedAt,
  required double totalKcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

List<CalorieEntry> _weeklySourceEntries({
  required DateTime startDay,
  required double dailyKcal,
}) {
  return <CalorieEntry>[
    for (var index = 0; index < 7; index += 1)
      _entry(
        id: 'source-$index',
        loggedAt: startDay.add(Duration(days: index, hours: 8)),
        totalKcal: dailyKcal,
      ),
  ];
}

List<HealthWeightSample> _stableBoundaryWeights({
  required DateTime startDay,
  required DateTime boundaryDay,
}) {
  return <HealthWeightSample>[
    HealthWeightSample(recordedAt: startDay, weightKg: 80),
    HealthWeightSample(recordedAt: boundaryDay, weightKg: 80),
  ];
}

DiaryHealthDayData _healthDayWithWorkout({
  required DateTime day,
  required int totalCalories,
}) {
  return DiaryHealthDayData(
    totalSteps: 0,
    workouts: <HealthWorkoutSession>[
      HealthWorkoutSession(
        id: 'workout-${diaryDayKey(day)}',
        start: day.add(const Duration(hours: 18)),
        endExclusive: day.add(const Duration(hours: 19)),
        durationMinutes: 60,
        activityLabel: 'Run',
        sourceName: 'Health',
        totalCalories: totalCalories,
        totalSteps: 0,
      ),
    ],
  );
}

void main() {
  test(
    'recalculates expected activity delta for a selected historical day',
    () async {
      final today = DateTime(2026, 4, 15);
      final selectedDay = DateTime(2026, 4, 14);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            dailyKcalGoal: 2100,
            changedAt: DateTime(2026, 4, 13, 9),
            calculatorProfile: null,
            expectedActivityKcal: 500,
          )
          .copyWith(
            activityTrackingStartDate: selectedDay,
          );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            diaryDayKey(selectedDay): DiaryHealthDayData(
              totalSteps: 5000,
              workouts: <HealthWorkoutSession>[
                HealthWorkoutSession(
                  id: 'history-run',
                  start: selectedDay.add(const Duration(hours: 18)),
                  endExclusive: selectedDay.add(const Duration(hours: 19)),
                  durationMinutes: 60,
                  activityLabel: 'Run',
                  sourceName: 'Health',
                  totalCalories: 400,
                  totalSteps: 0,
                ),
              ],
            ),
          },
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(selectedDay).future,
      );

      expect(resolvedGoal.day, normalizeDiaryDay(selectedDay));
      expect(resolvedGoal.storedGoalKcal, 2100);
      expect(resolvedGoal.goalKcal, 2150);
      expect(resolvedGoal.activityDeltaKcal, 50);
      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.expectedActivityKcal, 500);
      expect(resolvedGoal.todayActiveKcal, 600);
      expect(resolvedGoal.isActivityTrackingActive, isTrue);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.usesPreLearningActivityBonus, isTrue);
    },
  );

  test(
    'treats missing tracking start as today and ignores earlier health data',
    () async {
      final today = DateTime.now();
      final selectedDay = today.subtract(const Duration(days: 1));
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: const CalorieGoalSettings.empty().applyGoalChange(
          dailyKcalGoal: 2100,
          changedAt: DateTime(2026, 4, 13, 9),
          calculatorProfile: null,
          expectedActivityKcal: 500,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          calorieBalanceNowProvider.overrideWith(
            (ref) =>
                () => today,
          ),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          healthConnectionServiceProvider.overrideWith(
            (ref) => FakeHealthConnectionService(_readyStatus),
          ),
          diaryHealthServiceProvider.overrideWith(
            (ref) => FakeDiaryHealthService(
              <String, DiaryHealthDayData>{
                diaryDayKey(selectedDay): DiaryHealthDayData(
                  totalSteps: 5000,
                  workouts: <HealthWorkoutSession>[
                    HealthWorkoutSession(
                      id: 'before-tracking-run',
                      start: selectedDay.add(const Duration(hours: 18)),
                      endExclusive: selectedDay.add(
                        const Duration(hours: 19),
                      ),
                      durationMinutes: 60,
                      activityLabel: 'Run',
                      sourceName: 'Health',
                      totalCalories: 400,
                      totalSteps: 0,
                    ),
                  ],
                ),
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(settingsRepository.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(selectedDay).future,
      );
      final persistedSettings = await settingsRepository.readSettings();

      expect(persistedSettings.activityTrackingStartDate, isNull);
      expect(resolvedGoal.isActivityTrackingActive, isFalse);
      expect(resolvedGoal.todayActiveKcal, 0);
      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, 0);
      expect(resolvedGoal.goalKcal, 2100);
    },
  );

  test(
    'adds positive activity delta before learned TDEE on a full day',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            dailyKcalGoal: 2100,
            changedAt: DateTime(2026, 4, 14, 9),
            calculatorProfile: null,
            expectedActivityKcal: 500,
          )
          .copyWith(activityTrackingStartDate: today);
      final diaryHealthService = FakeDiaryHealthService(
        <String, DiaryHealthDayData>{
          diaryDayKey(today): DiaryHealthDayData(
            totalSteps: 5000,
            workouts: <HealthWorkoutSession>[
              HealthWorkoutSession(
                id: 'run-1',
                start: today.add(const Duration(hours: 18)),
                endExclusive: today.add(const Duration(hours: 19)),
                durationMinutes: 60,
                activityLabel: 'Run',
                sourceName: 'Health',
                totalCalories: 400,
                totalSteps: 0,
              ),
            ],
          ),
        },
      );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: diaryHealthService,
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.storedGoalKcal, 2100);
      expect(resolvedGoal.activityDeltaKcal, 50);
      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.expectedActivityKcal, 500);
      expect(resolvedGoal.goalKcal, 2150);
      expect(resolvedGoal.todayActiveKcal, 600);
      expect(resolvedGoal.isActivityTrackingActive, isTrue);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.usesPreLearningActivityBonus, isTrue);
    },
  );

  test(
    'ignores unassigned active energy without steps',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            dailyKcalGoal: 2100,
            changedAt: DateTime(2026, 4, 14, 9),
            calculatorProfile: null,
            expectedActivityKcal: 200,
          )
          .copyWith(activityTrackingStartDate: today);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            diaryDayKey(today): DiaryHealthDayData(
              totalSteps: 0,
              workouts: const <HealthWorkoutSession>[],
              unassignedActiveEnergySegments: [
                HealthEnergySegment(
                  id: 'unassigned-bike',
                  start: today.add(const Duration(hours: 18)),
                  endExclusive: today.add(const Duration(hours: 19)),
                  durationMinutes: 60,
                  sourceName: 'Health',
                  totalCalories: 300,
                  totalSteps: null,
                ),
              ],
            ),
          },
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.todayActiveKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, -200);
      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.goalKcal, 2100);
    },
  );

  test('does not add activity delta without an expected baseline', () async {
    final today = DateTime(2026, 4, 15, 18);
    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: today,
          dailyKcalGoal: 2100,
          calculatorProfile: null,
        )
        .copyWith(activityTrackingStartDate: today);

    final container = _createContainer(
      today: today,
      settings: settings,
      diaryHealthService: FakeDiaryHealthService(
        <String, DiaryHealthDayData>{
          diaryDayKey(today): DiaryHealthDayData(
            totalSteps: 0,
            workouts: <HealthWorkoutSession>[
              HealthWorkoutSession(
                id: 'lift-1',
                start: today.add(const Duration(minutes: 30)),
                endExclusive: today.add(const Duration(hours: 1, minutes: 30)),
                durationMinutes: 60,
                activityLabel: 'Weights',
                sourceName: 'Health',
                totalCalories: 500,
                totalSteps: 0,
              ),
            ],
          ),
        },
      ),
    );
    addTearDown(container.dispose);

    final resolvedGoal = await container.read(
      resolvedCalorieGoalForDayProvider(today).future,
    );

    expect(resolvedGoal.goalKcal, 2100);
    expect(resolvedGoal.activityDeltaKcal, 0);
    expect(resolvedGoal.activityComparisonKcal, 0);
    expect(resolvedGoal.expectedActivityKcal, 0);
    expect(resolvedGoal.todayActiveKcal, 500);
    expect(resolvedGoal.isActivityTrackingActive, isTrue);
    expect(resolvedGoal.usesPreLearningActivityBonus, isFalse);
  });

  test(
    'does not clamp a resolved goal above the 1200 floor',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 4, 14, 9),
        dailyKcalGoal: 1400,
        calculatorProfile: null,
      );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{},
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.storedGoalKcal, 1400);
      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, 0);
      expect(resolvedGoal.goalKcal, 1400);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.wasClampedToMinimum, isFalse);
    },
  );

  test(
    'same-day starter still compares against expected activity baseline',
    () async {
      final today = DateTime(2026, 4, 15, 0, 0, 0, 0, 1);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            expectedActivityKcal: 300,
          )
          .copyWith(activityTrackingStartDate: today);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            diaryDayKey(today): DiaryHealthDayData(
              totalSteps: 0,
              workouts: <HealthWorkoutSession>[
                HealthWorkoutSession(
                  id: 'micro-start-workout',
                  start: today.add(const Duration(hours: 1)),
                  endExclusive: today.add(const Duration(hours: 2)),
                  durationMinutes: 60,
                  activityLabel: 'Run',
                  sourceName: 'Health',
                  totalCalories: 450,
                  totalSteps: 0,
                ),
              ],
            ),
          },
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.goalKcal, 2175);
      expect(resolvedGoal.activityDeltaKcal, 75);
      expect(resolvedGoal.activityComparisonKcal, 150);
      expect(resolvedGoal.expectedActivityKcal, 300);
      expect(resolvedGoal.usesPreLearningActivityBonus, isTrue);
    },
  );

  test(
    'adds only positive learned activity bonus after weekly check-in',
    () async {
      final today = DateTime(2026, 4, 15);
      final sourceStart = today.subtract(const Duration(days: 7));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _weeklySourceEntries(
          startDay: sourceStart,
          dailyKcal: 2100,
        ),
      );
      addTearDown(logRepository.dispose);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: sourceStart,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: sourceStart,
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2100,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          )
          .copyWith(activityTrackingStartDate: today);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            diaryDayKey(today): _healthDayWithWorkout(
              day: today,
              totalCalories: 100,
            ),
          },
        ),
        logRepository: logRepository,
        healthWeightService: FakeHealthWeightService(
          _stableBoundaryWeights(startDay: sourceStart, boundaryDay: today),
        ),
        manualWeightRepository: FakeManualHealthWeightRepository(
          <ManualHealthWeightEntry>[],
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.activityDeltaKcal, 50);
      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.goalKcal, 2150);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
      expect(resolvedGoal.usesPreLearningActivityBonus, isFalse);
    },
  );

  test(
    'keeps learned target stable until the next weekly check-in',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final today = DateTime(2026, 4, 16);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 15),
            dailyKcalGoal: 2400,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: startDay,
              windowEndDate: DateTime(2026, 4, 14),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2400,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          )
          .copyWith(activityTrackingStartDate: today);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 8; index += 1)
            _entry(
              id: 'day-$index',
              loggedAt: startDay.add(Duration(days: index, hours: 8)),
              totalKcal: 2500,
            ),
        ],
      );
      final healthWeightService = FakeHealthWeightService(
        <HealthWeightSample>[
          HealthWeightSample(
            recordedAt: startDay.add(const Duration(hours: 7)),
            weightKg: 80,
          ),
          HealthWeightSample(
            recordedAt: today.add(const Duration(hours: 7)),
            weightKg: 79.2,
          ),
        ],
      );
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(logRepository.dispose);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
        logRepository: logRepository,
        healthWeightService: healthWeightService,
        manualWeightRepository: manualRepository,
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        resolvedCalorieGoalForDayProvider(today),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final resolvedToday = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );
      final resolvedHistorical = await container.read(
        resolvedCalorieGoalForDayProvider(DateTime(2026, 4, 15)).future,
      );

      expect(resolvedToday.storedGoalKcal, 2400);
      expect(resolvedToday.goalKcal, 2400);
      expect(resolvedToday.usedLearnedTdee, isTrue);
      expect(resolvedHistorical.storedGoalKcal, 2400);
      expect(resolvedHistorical.goalKcal, 2400);

      for (var index = 0; index < 8; index += 1) {
        await logRepository.saveEntry(
          _entry(
            id: 'day-$index',
            loggedAt: startDay.add(Duration(days: index, hours: 8)),
            totalKcal: 1000,
          ),
        );
      }
      container.read(calorieOverviewRevisionProvider.notifier).markChanged();

      final recomputedToday = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(recomputedToday.storedGoalKcal, 2400);
      expect(recomputedToday.goalKcal, 2400);
    },
  );

  test(
    'uses saved learned target when end weight is missing from health',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final today = DateTime(2026, 4, 15);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _weeklySourceEntries(
          startDay: startDay,
          dailyKcal: 2580,
        ),
      );
      addTearDown(logRepository.dispose);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: startDay,
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2580,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: startDay,
              windowEndDate: previousDiaryDay(today),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2580,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          const <String, DiaryHealthDayData>{},
        ),
        logRepository: logRepository,
        healthWeightService: FakeHealthWeightService(
          <HealthWeightSample>[
            HealthWeightSample(recordedAt: startDay, weightKg: 80),
          ],
        ),
        manualWeightRepository: FakeManualHealthWeightRepository(
          <ManualHealthWeightEntry>[],
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.storedGoalKcal, 2580);
      expect(resolvedGoal.goalKcal, 2580);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
    },
  );

  test(
    'recalculates learned activity comparison for a selected historical day',
    () async {
      final today = DateTime(2026, 4, 16);
      final selectedDay = DateTime(2026, 4, 15);
      final sourceStart = DateTime(2026, 4, 5);
      final sourceBoundary = DateTime(2026, 4, 12);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _weeklySourceEntries(
          startDay: sourceStart,
          dailyKcal: 2100,
        ),
      );
      addTearDown(logRepository.dispose);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: sourceStart,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: sourceBoundary,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: sourceStart,
              windowEndDate: previousDiaryDay(sourceBoundary),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2100,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          )
          .copyWith(activityTrackingStartDate: selectedDay);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            diaryDayKey(selectedDay): _healthDayWithWorkout(
              day: selectedDay,
              totalCalories: 100,
            ),
          },
        ),
        logRepository: logRepository,
        healthWeightService: FakeHealthWeightService(
          _stableBoundaryWeights(
            startDay: sourceStart,
            boundaryDay: sourceBoundary,
          ),
        ),
        manualWeightRepository: FakeManualHealthWeightRepository(
          <ManualHealthWeightEntry>[],
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(selectedDay).future,
      );

      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.activityDeltaKcal, 50);
      expect(resolvedGoal.goalKcal, 2150);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
      expect(resolvedGoal.usesPreLearningActivityBonus, isFalse);
    },
  );

  test(
    'does not lower learned goal on a rest day below the stored goal',
    () async {
      final today = DateTime(2026, 4, 15);
      final sourceStart = today.subtract(const Duration(days: 7));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _weeklySourceEntries(
          startDay: sourceStart,
          dailyKcal: 2000,
        ),
      );
      addTearDown(logRepository.dispose);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: sourceStart,
            dailyKcalGoal: 2000,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: sourceStart,
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2000,
              averageActiveKcal: 400,
              lowConfidence: false,
            ),
          )
          .copyWith(activityTrackingStartDate: today);

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{
            for (var index = 0; index < 7; index += 1)
              diaryDayKey(
                sourceStart.add(Duration(days: index)),
              ): _healthDayWithWorkout(
                day: sourceStart.add(Duration(days: index)),
                totalCalories: 400,
              ),
          },
        ),
        logRepository: logRepository,
        healthWeightService: FakeHealthWeightService(
          _stableBoundaryWeights(startDay: sourceStart, boundaryDay: today),
        ),
        manualWeightRepository: FakeManualHealthWeightRepository(
          <ManualHealthWeightEntry>[],
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, -400);
      expect(resolvedGoal.goalKcal, 2000);
      expect(resolvedGoal.wasClampedToMinimum, isFalse);
    },
  );

  test(
    'does not clamp a learned resolved goal above the 1200 floor',
    () async {
      final today = DateTime(2026, 4, 15);
      final sourceStart = today.subtract(const Duration(days: 7));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _weeklySourceEntries(
          startDay: sourceStart,
          dailyKcal: 1450,
        ),
      );
      addTearDown(logRepository.dispose);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: sourceStart,
            dailyKcalGoal: 1450,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 1450,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: sourceStart,
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 1450,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
          <String, DiaryHealthDayData>{},
        ),
        logRepository: logRepository,
        healthWeightService: FakeHealthWeightService(
          _stableBoundaryWeights(startDay: sourceStart, boundaryDay: today),
        ),
        manualWeightRepository: FakeManualHealthWeightRepository(
          <ManualHealthWeightEntry>[],
        ),
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.goalKcal, 1450);
      expect(resolvedGoal.wasClampedToMinimum, isFalse);
    },
  );
}
