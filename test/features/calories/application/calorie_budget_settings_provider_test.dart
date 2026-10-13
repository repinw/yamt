import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

const _notReadyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

CalorieEntry _entry(String id, DateTime day, double kcal) {
  final loggedAt = day.add(const Duration(hours: 12));
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  final goalStart = DateTime(2026, 4, 8);
  final today = addDiaryDays(goalStart, 16);

  CalorieGoalSettings settingsWithCheckIns() {
    var settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2400,
      calculatorProfile: null,
      effectiveDate: goalStart,
    );
    for (final week in [0, 1]) {
      final windowStart = addDiaryDays(goalStart, 7 * week);
      settings = settings.applyGoalChange(
        changedAt: addDiaryDays(windowStart, 7),
        dailyKcalGoal: 2400,
        calculatorProfile: null,
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: windowStart,
          windowEndDate: addDiaryDays(windowStart, 6),
          trendWeightChangePerDay: 0,
          calculatedTdeeKcal: 2500,
          lowConfidence: false,
        ),
      );
    }
    return settings;
  }

  late FakeCalorieLogRepository logRepository;
  late ProviderContainer container;

  setUp(() {
    logRepository = FakeCalorieLogRepository(
      initialEntries: [
        for (var day = 0; day < 16; day++)
          _entry('entry-$day', addDiaryDays(goalStart, day), 2500),
      ],
    );
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWith(
          (ref) =>
              () => today,
        ),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(
          FakeCalorieSettingsRepository(
            initialSettings: settingsWithCheckIns(),
          ),
        ),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_notReadyStatus),
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => FakeManualHealthWeightRepository([
            for (var day = 0; day < 16; day++)
              ManualHealthWeightEntry(
                day: addDiaryDays(goalStart, day),
                weightKg: 80,
              ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(logRepository.dispose);
  });

  Future<Map<String, double>> offsets() async {
    await container.read(goalTdeeOffsetsByDayProvider.future);
    await pumpEventQueue();
    return (await container.read(goalTdeeOffsetsByDayProvider.future)).byDay;
  }

  test('moves each counting day with the daily TDEE', () async {
    container.listen(calorieBudgetSettingsProvider, (_, _) {});
    final offsetsByDay = await offsets();
    final budget = await container.read(calorieBudgetSettingsProvider.future);
    final stored = settingsWithCheckIns();

    // The first week rests on a goal without check-in or profile; the
    // finished second week keeps its offsets.
    expect(offsetsByDay.keys, [
      for (var day = 7; day <= 20; day++)
        diaryDayKey(addDiaryDays(goalStart, day)),
    ]);
    for (var day = 0; day <= 20; day++) {
      final date = addDiaryDays(goalStart, day);
      expect(
        budget.goalKcalForDay(date),
        closeTo(
          stored.goalKcalForDay(date) + (offsetsByDay[diaryDayKey(date)] ?? 0),
          1e-9,
        ),
      );
    }
  });

  test('recomputes when an entry of the running week changes', () async {
    container.listen(calorieBudgetSettingsProvider, (_, _) {});
    final before = (await offsets())[diaryDayKey(today)]!;

    await logRepository.saveEntry(
      _entry('extra', previousDiaryDay(today), 1500),
    );
    final after = (await offsets())[diaryDayKey(today)]!;

    expect(after, greaterThan(before));
  });
}
