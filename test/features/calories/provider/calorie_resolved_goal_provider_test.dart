import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';

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
}) {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  return ProviderContainer(
    overrides: [
      calorieBalanceNowProvider.overrideWith(
        (ref) =>
            () => today,
      ),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      healthConnectionServiceProvider.overrideWith(
        (ref) =>
            healthConnectionService ??
            FakeHealthConnectionService(_readyStatus),
      ),
      diaryHealthServiceProvider.overrideWith((ref) => diaryHealthService),
    ],
  );
}

void main() {
  test(
    'recalculates bootstrap workout bonus for a selected historical day',
    () async {
      final today = DateTime(2026, 4, 15);
      final selectedDay = DateTime(2026, 4, 14);
      final settings = const CalorieGoalSettings.empty().applyGoalChange(
        dailyKcalGoal: 2100,
        changedAt: DateTime(2026, 4, 13, 9),
        calculatorProfile: null,
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
      expect(resolvedGoal.goalKcal, 2240);
      expect(resolvedGoal.activityDeltaKcal, 140);
      expect(resolvedGoal.activityComparisonKcal, 0);
      expect(resolvedGoal.todayActiveKcal, 600);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.usesBootstrapActivityBonus, isTrue);
    },
  );

  test(
    'adds bootstrap workout bonus before learned TDEE on a full day',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty().applyGoalChange(
        dailyKcalGoal: 2100,
        changedAt: DateTime(2026, 4, 14, 9),
        calculatorProfile: null,
      );
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
      expect(resolvedGoal.activityDeltaKcal, 140);
      expect(resolvedGoal.activityComparisonKcal, 0);
      expect(resolvedGoal.goalKcal, 2240);
      expect(resolvedGoal.todayActiveKcal, 600);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.usesBootstrapActivityBonus, isTrue);
    },
  );

  test('skips bootstrap workout bonus on a partial first day', () async {
    final today = DateTime(2026, 4, 15, 18);
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: today,
      dailyKcalGoal: 2100,
      calculatorProfile: null,
    );

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
    expect(resolvedGoal.usesBootstrapActivityBonus, isFalse);
  });

  test(
    'clamps a bootstrap resolved goal to 1500 when stored goal is lower',
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
      expect(resolvedGoal.goalKcal, minimumResolvedDailyCalorieGoalKcal);
      expect(resolvedGoal.usedLearnedTdee, isFalse);
      expect(resolvedGoal.wasClampedToMinimum, isTrue);
    },
  );

  test(
    'skips bootstrap workout bonus when first-day start has only microseconds',
    () async {
      final today = DateTime(2026, 4, 15, 0, 0, 0, 0, 1);
      final settings = const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: today,
        dailyKcalGoal: 2100,
        calculatorProfile: null,
      );

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

      expect(resolvedGoal.goalKcal, 2100);
      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, 0);
      expect(resolvedGoal.usesBootstrapActivityBonus, isFalse);
    },
  );

  test(
    'adds only positive learned activity bonus after weekly check-in',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2200,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: today.subtract(const Duration(days: 7)),
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2300,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
          );

      final container = _createContainer(
        today: today,
        settings: settings,
        diaryHealthService: FakeDiaryHealthService(
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
                  totalCalories: 100,
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

      expect(resolvedGoal.activityDeltaKcal, 100);
      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.goalKcal, 2200);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
      expect(resolvedGoal.usesBootstrapActivityBonus, isFalse);
    },
  );

  test(
    'recalculates learned activity comparison for a selected historical day',
    () async {
      final today = DateTime(2026, 4, 16);
      final selectedDay = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2200,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 12),
            dailyKcalGoal: 2100,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: DateTime(2026, 4, 5),
              windowEndDate: DateTime(2026, 4, 11),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2300,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
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
                  id: 'history-learned-run',
                  start: selectedDay.add(const Duration(hours: 18)),
                  endExclusive: selectedDay.add(const Duration(hours: 19)),
                  durationMinutes: 60,
                  activityLabel: 'Run',
                  sourceName: 'Health',
                  totalCalories: 100,
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

      expect(resolvedGoal.activityComparisonKcal, 100);
      expect(resolvedGoal.activityDeltaKcal, 100);
      expect(resolvedGoal.goalKcal, 2200);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
      expect(resolvedGoal.usesBootstrapActivityBonus, isFalse);
    },
  );

  test(
    'does not lower learned goal on a rest day below the stored goal',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: today.subtract(const Duration(days: 7)),
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2200,
              averageActiveKcal: 400,
              lowConfidence: false,
            ),
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

      expect(resolvedGoal.activityDeltaKcal, 0);
      expect(resolvedGoal.activityComparisonKcal, -400);
      expect(resolvedGoal.goalKcal, 2000);
      expect(resolvedGoal.wasClampedToMinimum, isFalse);
    },
  );

  test(
    'clamps a learned resolved goal to 1500 when stored goal is below minimum',
    () async {
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 1600,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 1450,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: today.subtract(const Duration(days: 7)),
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2000,
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
      );
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.goalKcal, 1500);
      expect(resolvedGoal.wasClampedToMinimum, isTrue);
    },
  );
}
