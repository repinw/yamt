import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';

import '../support/fake_calories_repositories.dart';

CalorieEntry _entry(
  String id, {
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

void main() {
  test(
    'calorieBalanceSummary starts at zero before the eating window',
    () async {
      final now = DateTime(2026, 4, 10, 5, 30);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'early',
            loggedAt: day.add(const Duration(hours: 5)),
            totalKcal: 300,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: day.subtract(const Duration(days: 6)),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieBalanceNowProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.read(calorieDayControllerProvider.notifier).setDay(day);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.paceRatio, 0.0);
      expect(summary.pacedGoalKcal, 0.0);
    },
  );

  test(
    'calorieBalanceSummary uses the eating-window midpoint for pacing',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _historyEntries(day),
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: day.subtract(const Duration(days: 6)),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieBalanceNowProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.read(calorieDayControllerProvider.notifier).setDay(day);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.paceRatio, closeTo(0.5, 0.0001));
      expect(summary.pacedGoalKcal, closeTo(1000, 0.001));
    },
  );

  test(
    'calorieBalanceSummary is fully paced after the eating window',
    () async {
      final now = DateTime(2026, 4, 10, 22, 30);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _historyEntries(day),
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: day.subtract(const Duration(days: 6)),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieBalanceNowProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.read(calorieDayControllerProvider.notifier).setDay(day);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.paceRatio, 1.0);
      expect(summary.pacedGoalKcal, 2000);
    },
  );

  test(
    'calorieBalanceSummary falls back when reading history range fails',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository();
      logRepository.onReadEntriesInRange = (_, _) async {
        throw StateError('history read failed');
      };
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: day.subtract(const Duration(days: 6)),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieBalanceNowProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      container.read(calorieDayControllerProvider.notifier).setDay(day);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.carryoverKcal, 12000);
      expect(summary.flexibleGoalKcal, 14000);
      expect(summary.pacedGoalKcal, 7000);
    },
  );

  test('lose mode rewards eating below pace more than above pace', () {
    final underPace = _summaryData(
      goalMode: CalorieGoalMode.lose,
      deltaKcal: -220,
    );
    final overPace = _summaryData(
      goalMode: CalorieGoalMode.lose,
      deltaKcal: 220,
    );

    expect(
      resolveCalorieBalanceScore(underPace),
      greaterThan(resolveCalorieBalanceScore(overPace)),
    );
  });

  test('gain mode rewards eating above pace more than below pace', () {
    final underPace = _summaryData(
      goalMode: CalorieGoalMode.gain,
      deltaKcal: -220,
    );
    final overPace = _summaryData(
      goalMode: CalorieGoalMode.gain,
      deltaKcal: 220,
    );

    expect(
      resolveCalorieBalanceScore(overPace),
      greaterThan(resolveCalorieBalanceScore(underPace)),
    );
  });

  test('maintain mode gets redder with larger deviations on either side', () {
    final slightDeviation = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 120,
    );
    final largeDeviation = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 520,
    );

    expect(
      resolveCalorieBalanceScore(slightDeviation),
      greaterThan(resolveCalorieBalanceScore(largeDeviation)),
    );
    expect(resolveCalorieBalanceCenterScore(slightDeviation), 1.0);
  });
}

List<CalorieEntry> _historyEntries(DateTime selectedDay) {
  return <CalorieEntry>[
    for (var daysBack = 1; daysBack <= 6; daysBack += 1)
      _entry(
        'history-$daysBack',
        loggedAt: selectedDay.subtract(Duration(days: daysBack)),
        totalKcal: 2000,
      ),
  ];
}

CalorieBalanceSummaryData _summaryData({
  required CalorieGoalMode goalMode,
  required double deltaKcal,
}) {
  final now = DateTime(2026, 4, 10, 14);
  return CalorieBalanceSummaryData(
    selectedDay: normalizeDiaryDay(now),
    referenceNow: now,
    windowStartDate: now.subtract(const Duration(days: 6)),
    balanceStartDate: now.subtract(const Duration(days: 6)),
    baseGoalKcal: 2000,
    carryoverKcal: 0,
    goalMode: goalMode,
    flexibleGoalKcal: 2000,
    pacedGoalKcal: 1000,
    consumedKcal: 1000 + deltaKcal,
    deltaKcal: deltaKcal,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
  );
}
