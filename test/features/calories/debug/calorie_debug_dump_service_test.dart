import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/debug/calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
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
            unassignedActiveEnergySegments: <HealthEnergySegment>[
              HealthEnergySegment(
                id: 'energy-1',
                start: day.add(const Duration(hours: 15)),
                endExclusive: day.add(const Duration(hours: 15, minutes: 30)),
                durationMinutes: 30,
                sourceName: 'Health',
                totalCalories: 120,
                totalSteps: 800,
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
            calculatorProfile: const CalorieCalculatorProfile.defaults(),
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
      expect(result.table, contains('week_1_start'));
      expect(result.table, contains('tdee_source=calculator_profile'));
      expect(result.table, contains('weight_kg=80'));
      expect(result.table, contains('height_cm=180'));
      expect(result.table, contains('age_years=30'));
      expect(result.table, contains('tdee=2136'));
      expect(result.table, contains('week_1_summary'));
      expect(result.table, contains('calculated_goal_total=2000'));
      expect(result.table, contains('eaten_total=420'));
      expect(result.table, contains('weight_change=0'));
      expect(result.table, contains('activity_day'));
      expect(result.table, contains('activity_total'));
      expect(result.table, contains('steps_outside_workouts=0'));
      expect(result.table, contains('workout_kcal=500'));
      expect(result.table, contains('unassigned_active_energy_kcal=120'));
      expect(result.table, isNot(contains('Run')));
      expect(result.table, isNot(contains('workout |')));
      expect(result.table, isNot(contains('manual_fallback')));
      expect(result.table, contains('health'));
      expect(result.table, isNot(contains('2026-04-09')));
      expect(result.rowCount, 6);
    },
  );

  test('buildCalorieDebugDump hides rows before first goal window', () async {
    final oldDay = DateTime(2026, 4);
    final goalStart = DateTime(2026, 4, 8);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          id: 'old-food',
          name: 'Old food',
          loggedAt: oldDay.add(const Duration(hours: 12)),
          kcal: 1000,
        ),
        _entry(
          id: 'goal-food',
          name: 'Goal food',
          loggedAt: goalStart.add(const Duration(hours: 12)),
          kcal: 2000,
        ),
      ],
    );
    final diaryHealthService = FakeDiaryHealthService(
      <String, DiaryHealthDayData>{
        diaryDayKey(oldDay): const DiaryHealthDayData(
          totalSteps: 9000,
          workouts: <HealthWorkoutSession>[],
        ),
        diaryDayKey(goalStart): const DiaryHealthDayData(
          totalSteps: 4000,
          workouts: <HealthWorkoutSession>[],
        ),
      },
    );
    final healthWeightService = FakeHealthWeightService(<HealthWeightSample>[
      HealthWeightSample(
        recordedAt: oldDay.add(const Duration(hours: 7)),
        weightKg: 85,
      ),
      HealthWeightSample(
        recordedAt: goalStart.add(const Duration(hours: 7)),
        weightKg: 84,
      ),
    ]);
    final manualWeightRepository = FakeManualHealthWeightRepository(
      const <ManualHealthWeightEntry>[],
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
          effectiveDate: goalStart,
        ),
      ),
      now: goalStart.add(const Duration(hours: 20)),
    );

    expect(result.table, contains('| 2026-04-08 |  | summary |'));
    expect(result.table, contains('| 2026-04-08 |  | eaten_day |'));
    expect(result.table, contains('| 2026-04-08 |  | activity_day |'));
    expect(result.table, contains('| 2026-04-08 |  | weight |'));
    expect(result.table, contains('week_1_start'));
    expect(result.table, contains('week_1_summary'));
    expect(result.table, isNot(contains('2026-04-01')));
    expect(result.rowCount, 6);
  });

  test('buildCalorieDebugDump cascades exact weekly check-in goals', () async {
    final start = DateTime(2026, 4, 8);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var index = 0; index < 14; index += 1)
          _entry(
            id: 'food-$index',
            name: 'Day $index food',
            loggedAt: addDiaryDays(start, index).add(
              const Duration(hours: 12),
            ),
            kcal: 2002,
          ),
      ],
    );
    final diaryHealthService = FakeDiaryHealthService(
      <String, DiaryHealthDayData>{
        for (var index = 0; index < 15; index += 1)
          diaryDayKey(addDiaryDays(start, index)): const DiaryHealthDayData(
            totalSteps: 0,
            workouts: <HealthWorkoutSession>[],
          ),
      },
    );
    final healthWeightService = FakeHealthWeightService(<HealthWeightSample>[
      for (var index = 0; index < 14; index += 1)
        HealthWeightSample(
          recordedAt: addDiaryDays(start, index).add(
            const Duration(hours: 7),
          ),
          weightKg: 84,
        ),
    ]);
    final manualWeightRepository = FakeManualHealthWeightRepository(
      const <ManualHealthWeightEntry>[],
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
          effectiveDate: start,
        ),
      ),
      now: DateTime(2026, 4, 22, 12),
    );

    expect(result.table, contains('weekly_checkin'));
    expect(result.table, contains('learned_base_tdee'));
    expect(result.table, contains('planned_vs_eaten'));
    expect(result.table, contains('weight_trend'));
    expect(result.table, contains('measured_total_tdee'));
    expect(result.table, contains('measured_base_tdee'));
    expect(result.table, contains('new_target'));
    expect(result.table, contains('week_1_start'));
    expect(result.table, contains('week_1_summary'));
    expect(result.table, contains('week_2_start'));
    expect(result.table, contains('week_2_summary'));
    expect(result.table, contains('week_3_start'));
    expect(result.table, contains('week_3_summary'));
    expect(
      result.table,
      contains('| 2026-04-15 |  | week | week_2_start | 2000.60 |'),
    );
    expect(
      result.table,
      contains('| 2026-04-22 |  | week | week_3_start | 2001.02 |'),
    );
    expect(result.table, contains('tdee_source=learned_tdee'));
    expect(
      result.table,
      contains('calculated_from_window=2026-4-8..2026-4-14'),
    );
    expect(result.table, contains('calculated_goal_total=14000'));
    expect(result.table, contains('eaten_minus_goal=14'));
    expect(result.table, contains('window=2026-4-8..2026-4-14'));
    expect(result.table, contains('window=2026-4-15..2026-4-21'));
    expect(result.table, contains('\n\n| 2026-04-15 |'));
    expect(result.table, contains('\n\n| 2026-04-22 |'));
    expect(result.table, contains('learning_window=2026-4-8..2026-4-14'));
    expect(result.table, contains('learning_window=2026-4-8..2026-4-21'));
    expect(result.table, contains('previous_goal=2000'));
    expect(result.table, contains('previous_goal=2000.60'));
    expect(result.table, contains('planned_total=14000'));
    expect(result.table, contains('eaten_total=14014'));
    expect(result.table, contains('weight_change=0'));
    expect(
      result.table,
      contains('formula=average_eaten - weight_storage_per_day'),
    );
    expect(
      result.table,
      contains('formula=measured_total_tdee - credited_activity_average'),
    );
    expect(result.table, contains('activity_subtracted_from_total_tdee=0'));
    expect(result.table, contains('learned_base_tdee=2000.60'));
    expect(result.table, contains('new_target=2000.60'));
  });

  test(
    'buildCalorieDebugDump hides activity tdee fields without health',
    () async {
      final start = DateTime(2026, 4, 8);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var index = 0; index < 7; index += 1)
            _entry(
              id: 'food-$index',
              name: 'Day $index food',
              loggedAt: addDiaryDays(start, index).add(
                const Duration(hours: 12),
              ),
              kcal: 2000,
            ),
        ],
      );
      final manualWeightRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[
          for (var index = 0; index < 7; index += 1)
            ManualHealthWeightEntry(
              day: addDiaryDays(start, index),
              weightKg: 84,
            ),
        ],
      );

      final result = await buildCalorieDebugDump(
        calorieLogRepository: logRepository,
        diaryHealthService: FakeDiaryHealthService(const {}),
        healthWeightService: FakeHealthWeightService(const []),
        manualWeightRepository: manualWeightRepository,
        healthStatusFuture: Future<HealthConnectionStatus>.value(
          const HealthConnectionStatus.unsupported(),
        ),
        settingsFuture: Future<CalorieGoalSettings>.value(
          CalorieGoalSettings.single(
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            effectiveDate: start,
          ),
        ),
        now: DateTime(2026, 4, 15, 12),
      );

      expect(result.table, contains('weekly_checkin'));
      expect(result.table, contains('measured_total_tdee'));
      expect(result.table, contains('new_target'));
      expect(result.table, isNot(contains('measured_base_tdee')));
      expect(result.table, isNot(contains('credited_activity_average')));
      expect(
        result.table,
        isNot(contains('activity_subtracted_from_total_tdee')),
      );
      expect(result.table, isNot(contains('dynamic_target_today')));
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
