import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
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

void main() {
  test(
    'buildCalorieDebugDump prints daily eaten activity and weight rows',
    () async {
      final day = DateTime(2026, 4, 10);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            id: 'food-1',
            name: 'Oats',
            loggedAt: day.add(const Duration(hours: 8)),
            kcal: 420,
          ),
        ],
      );
      final diaryHealthService = FakeDiaryHealthService(
        <String, DiaryHealthDayData>{
          diaryDayKey(day): DiaryHealthDayData(
            totalSteps: 6500,
            workouts: <HealthWorkoutSession>[
              HealthWorkoutSession(
                id: 'run-1',
                start: day.add(const Duration(hours: 18)),
                endExclusive: day.add(const Duration(hours: 19)),
                durationMinutes: 60,
                activityLabel: 'Run',
                sourceName: 'Health',
                totalCalories: 500,
                totalSteps: 7000,
              ),
            ],
          ),
        },
      );
      final healthWeightService = FakeHealthWeightService(<HealthWeightSample>[
        HealthWeightSample(
          recordedAt: day.add(const Duration(hours: 7)),
          weightKg: 81.2,
        ),
      ]);
      final manualWeightRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          ManualHealthWeightEntry(
            day: day.subtract(const Duration(days: 1)),
            weightKg: 81.5,
          ),
        ],
      );

      final result = await buildCalorieDebugDump(
        calorieLogRepository: logRepository,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        manualWeightRepository: manualWeightRepository,
        healthStatusFuture: Future<HealthConnectionStatus>.value(_readyStatus),
        settingsFuture: Future<CalorieGoalSettings>.value(
          CalorieGoalSettings.single(
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            effectiveDate: day,
          ),
        ),
        now: day.add(const Duration(hours: 20)),
      );

      expect(result.table, contains('| date | time | type | name | kcal |'));
      expect(result.table, contains('calorie_debug_dump'));
      expect(result.table, isNot(contains('Oats')));
      expect(result.table, contains('eaten_day'));
      expect(result.table, contains('eaten_total'));
      expect(result.table, contains('entries=1'));
      expect(result.table, contains('activity_day'));
      expect(result.table, contains('steps_total'));
      expect(result.table, contains('Run'));
      expect(result.table, contains('manual_fallback'));
      expect(result.table, contains('health'));
      expect(result.rowCount, 6);
    },
  );
}

CalorieEntry _entry({
  required String id,
  required String name,
  required DateTime loggedAt,
  required double kcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: name,
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
