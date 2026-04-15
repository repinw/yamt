import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
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
    'adds today activity delta to stored goal when learned TDEE exists',
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
              trendWeightChangePerDay: -0.05,
              calculatedTrueTdeeKcal: 2300,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
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
                totalCalories: 100,
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
      expect(resolvedGoal.activityDeltaKcal, 100);
      expect(resolvedGoal.goalKcal, 2200);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
    },
  );

  test('clamps today resolved goal to 1500', () async {
    final today = DateTime(2026, 4, 15);
    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 4, 1, 9),
          dailyKcalGoal: 1500,
          calculatorProfile: null,
        )
        .applyGoalChange(
          changedAt: today,
          dailyKcalGoal: 1500,
          calculatorProfile: null,
          source: CalorieGoalSource.weeklyCheckIn,
          weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
            windowStartDate: today.subtract(const Duration(days: 7)),
            windowEndDate: today.subtract(const Duration(days: 1)),
            trendWeightChangePerDay: -0.05,
            calculatedTrueTdeeKcal: 2000,
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

    expect(resolvedGoal.goalKcal, 1500);
    expect(resolvedGoal.wasClampedToMinimum, isTrue);
  });
}
