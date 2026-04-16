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
          ..._historyEntries(day),
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
    'calorieBalanceSummary uses a custom eating window for pacing',
    () async {
      final now = DateTime(2026, 4, 10, 15);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: _historyEntries(day),
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: day.subtract(const Duration(days: 6)),
          eatingWindowStartMinuteOfDay: 9 * 60,
          eatingWindowEndMinuteOfDay: 21 * 60,
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
    'calorieBalanceSummary stays at zero exactly at eating window start',
    () async {
      final now = DateTime(2026, 4, 10, 6);
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

      expect(summary.paceRatio, 0.0);
      expect(summary.pacedGoalKcal, 0.0);
    },
  );

  test(
    'calorieBalanceSummary is fully paced exactly at eating window end',
    () async {
      final now = DateTime(2026, 4, 10, 22);
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
    'calorieBalanceSummary adds full carryover to todays paced base goal',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var daysBack = 2; daysBack <= 6; daysBack += 1)
            _entry(
              'history-$daysBack',
              loggedAt: day.subtract(Duration(days: daysBack)),
              totalKcal: 2000,
            ),
          _entry(
            'yesterday-buffer',
            loggedAt: day.subtract(const Duration(days: 1)),
            totalKcal: 1800,
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

      expect(summary.carryoverKcal, 200);
      expect(summary.paceRatio, closeTo(0.5, 0.0001));
      expect(summary.pacedGoalKcal, closeTo(1200, 0.001));
    },
  );

  test('calorieBalanceSummary prorates todays goal from first goal time '
      'when no earlier diary entries exist today', () async {
    final now = DateTime(2026, 4, 10, 19);
    final day = normalizeDiaryDay(now);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'after-goal',
          loggedAt: day.add(const Duration(hours: 18)),
          totalKcal: 400,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 4, 10, 16),
        dailyKcalGoal: 2000,
        calculatorProfile: null,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieBalanceNowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.read(calorieDayControllerProvider.notifier).setDay(day);

    final summary = await container.read(calorieBalanceSummaryProvider.future);

    expect(summary.baseGoalKcal, closeTo(750, 0.001));
    expect(summary.flexibleGoalKcal, closeTo(750, 0.001));
    expect(summary.paceRatio, closeTo(0.5, 0.0001));
    expect(summary.pacedGoalKcal, closeTo(375, 0.001));
  });

  test('calorieBalanceSummary keeps full-day pacing when diary already '
      'had entries before goal was first set today', () async {
    final now = DateTime(2026, 4, 10, 19);
    final day = normalizeDiaryDay(now);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'before-goal',
          loggedAt: day.add(const Duration(hours: 12)),
          totalKcal: 300,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 4, 10, 16),
        dailyKcalGoal: 2000,
        calculatorProfile: null,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieBalanceNowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.read(calorieDayControllerProvider.notifier).setDay(day);

    final summary = await container.read(calorieBalanceSummaryProvider.future);

    expect(summary.paceRatio, closeTo(13 / 16, 0.0001));
    expect(summary.pacedGoalKcal, closeTo(1625, 0.001));
  });

  test(
    'calorieBalanceSummary carries a partial first-day surplus '
    'into the next day',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final selectedDay = DateTime(2026, 4, 9);
      final cycleStartDay = selectedDay.subtract(const Duration(days: 1));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'partial-start',
            loggedAt: cycleStartDay.add(const Duration(hours: 18, minutes: 30)),
            totalKcal: 734,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: const CalorieGoalSettings.empty().applyGoalChange(
          changedAt: DateTime(2026, 4, 8, 18),
          dailyKcalGoal: 2136,
          calculatorProfile: null,
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
      container.read(calorieDayControllerProvider.notifier).setDay(selectedDay);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.balanceStartDate, cycleStartDay);
      expect(summary.baseGoalKcal, 2136);
      expect(summary.carryoverKcal, closeTo(-200, 0.001));
      expect(summary.flexibleGoalKcal, closeTo(1936, 0.001));
      expect(summary.pacedGoalKcal, closeTo(1936, 0.001));
    },
  );

  test(
    'calorieBalanceSummary keeps carryover from before the visible week',
    () async {
      final now = DateTime(2026, 4, 11, 14);
      final selectedDay = DateTime(2026, 4, 10);
      final cycleStartDay = selectedDay.subtract(const Duration(days: 9));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'cycle-start-surplus',
            loggedAt: cycleStartDay.add(const Duration(hours: 12)),
            totalKcal: 2300,
          ),
          for (var offset = 1; offset <= 8; offset += 1)
            _entry(
              'balanced-$offset',
              loggedAt: cycleStartDay.add(
                Duration(days: offset, hours: 12),
              ),
              totalKcal: 2000,
            ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: cycleStartDay,
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
      container.read(calorieDayControllerProvider.notifier).setDay(selectedDay);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.balanceStartDate, cycleStartDay);
      expect(summary.carryoverKcal, closeTo(-300, 0.001));
      expect(summary.flexibleGoalKcal, closeTo(1700, 0.001));
      expect(summary.pacedGoalKcal, closeTo(1700, 0.001));
    },
  );

  test(
    'calorieBalanceSummary uses the final flexible goal for past days',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final selectedDay = normalizeDiaryDay(
        now.subtract(const Duration(days: 1)),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var daysBack = 2; daysBack <= 6; daysBack += 1)
            _entry(
              'history-$daysBack',
              loggedAt: normalizeDiaryDay(
                now,
              ).subtract(Duration(days: daysBack)),
              totalKcal: daysBack == 2 ? 1800 : 2000,
            ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: selectedDay.subtract(const Duration(days: 5)),
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
      container.read(calorieDayControllerProvider.notifier).setDay(selectedDay);

      final summary = await container.read(
        calorieBalanceSummaryProvider.future,
      );

      expect(summary.isCurrentDay, isFalse);
      expect(summary.carryoverKcal, 200);
      expect(summary.flexibleGoalKcal, 2200);
      expect(summary.pacedGoalKcal, 2200);
    },
  );

  test(
    'calorieBalanceSummary falls back when reading history range fails',
    () async {
      final now = DateTime(2026, 4, 10, 14);
      final day = normalizeDiaryDay(now);
      final logRepository = FakeCalorieLogRepository()
        ..onReadEntriesInRange = (_, _) async {
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
      expect(summary.pacedGoalKcal, 13000);
    },
  );

  test(
    'calorieBalanceSummary stays neutral before a future goal start',
    () async {
      final now = DateTime(2026, 4, 10, 18, 30);
      final day = normalizeDiaryDay(now);
      final tomorrow = day.add(const Duration(days: 1));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'today',
            loggedAt: day.add(const Duration(hours: 12)),
            totalKcal: 900,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: tomorrow,
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

      expect(summary.balanceStartDate, tomorrow);
      expect(summary.baseGoalKcal, 0);
      expect(summary.carryoverKcal, 0);
      expect(summary.flexibleGoalKcal, 0);
      expect(summary.pacedGoalKcal, 0);
      expect(summary.consumedKcal, 0);
      expect(summary.deltaKcal, 0);
    },
  );

  test('recommendsFastingToday when uncapped flex goal is exactly zero', () {
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 0,
      carryoverKcal: -2000,
      flexibleGoalKcal: 0,
      pacedGoalKcal: 0,
      consumedKcal: 0,
    );

    expect(summary.uncappedFlexibleGoalKcal, 0);
    expect(summary.recommendsFastingToday, isTrue);
    expect(summary.recommendsFastingRestOfDay, isFalse);
  });

  test('does not recommend full-day fasting when flex goal stays positive', () {
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 0,
      carryoverKcal: -1999,
      flexibleGoalKcal: 1,
      pacedGoalKcal: 0,
      consumedKcal: 0,
    );

    expect(summary.uncappedFlexibleGoalKcal, 1);
    expect(summary.recommendsFastingToday, isFalse);
  });

  test('recommends fasting for the rest of the day at the exact flex goal', () {
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 461,
      baseGoalKcal: 2427,
      carryoverKcal: -1874,
      flexibleGoalKcal: 553,
      pacedGoalKcal: 92,
      consumedKcal: 553,
    );

    expect(summary.recommendsFastingToday, isFalse);
    expect(summary.recommendsFastingRestOfDay, isTrue);
  });

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

  test('resolveCalorieBalanceRecoveryTime returns null for past days', () {
    final now = DateTime(2026, 4, 10, 14);
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 220,
      selectedDay: normalizeDiaryDay(now.subtract(const Duration(days: 1))),
      referenceNow: now,
    );

    expect(resolveCalorieBalanceRecoveryTime(summary), isNull);
  });

  test('resolveCalorieBalanceRecoveryTime returns null when not over pace', () {
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 20,
    );

    expect(resolveCalorieBalanceRecoveryTime(summary), isNull);
  });

  test(
    'resolveCalorieBalanceRecoveryTime returns null '
    'when recovery is impossible',
    () {
      final summary = _summaryData(
        goalMode: CalorieGoalMode.maintain,
        deltaKcal: 700,
        baseGoalKcal: 1000,
        flexibleGoalKcal: 1000,
        pacedGoalKcal: 500,
        consumedKcal: 1200,
      );

      expect(resolveCalorieBalanceRecoveryTime(summary), isNull);
    },
  );

  test('resolveCalorieBalanceRecoveryTime returns the expected time', () {
    final summary = _summaryData(
      goalMode: CalorieGoalMode.maintain,
      deltaKcal: 220,
      baseGoalKcal: 960,
      flexibleGoalKcal: 960,
      pacedGoalKcal: 480,
      consumedKcal: 700,
    );

    expect(
      resolveCalorieBalanceRecoveryTime(summary),
      DateTime(2026, 4, 10, 16, 40),
    );
  });

  test(
    'resolveCalorieBalanceRecoveryTime uses the effective pace window start',
    () {
      final summary = _summaryData(
        goalMode: CalorieGoalMode.maintain,
        deltaKcal: 200,
        referenceNow: DateTime(2026, 4, 10, 18),
        flexibleGoalKcal: 2000,
        pacedGoalKcal: 0,
        consumedKcal: 200,
        paceRatio: 0,
        deadZoneKcal: 0,
      ).copyWithPaceWindowStart(DateTime(2026, 4, 10, 18));

      expect(
        resolveCalorieBalanceRecoveryTime(summary),
        DateTime(2026, 4, 10, 18, 24),
      );
    },
  );
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
  DateTime? selectedDay,
  DateTime? referenceNow,
  double baseGoalKcal = 2000,
  double carryoverKcal = 0,
  double? flexibleGoalKcal,
  double? pacedGoalKcal,
  double? consumedKcal,
  double paceRatio = 0.5,
  double deadZoneKcal = 60,
  double rangeKcal = 600,
}) {
  final now = referenceNow ?? DateTime(2026, 4, 10, 14);
  final resolvedSelectedDay = selectedDay ?? normalizeDiaryDay(now);
  final resolvedFlexibleGoalKcal = flexibleGoalKcal ?? baseGoalKcal;
  final resolvedPacedGoalKcal = pacedGoalKcal ?? (baseGoalKcal * paceRatio);
  return CalorieBalanceSummaryData(
    selectedDay: resolvedSelectedDay,
    referenceNow: now,
    windowStartDate: now.subtract(const Duration(days: 6)),
    balanceStartDate: now.subtract(const Duration(days: 6)),
    paceWindowStart: DateTime(
      resolvedSelectedDay.year,
      resolvedSelectedDay.month,
      resolvedSelectedDay.day,
      6,
    ),
    paceWindowEnd: DateTime(
      resolvedSelectedDay.year,
      resolvedSelectedDay.month,
      resolvedSelectedDay.day,
      22,
    ),
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    goalMode: goalMode,
    flexibleGoalKcal: resolvedFlexibleGoalKcal,
    pacedGoalKcal: resolvedPacedGoalKcal,
    consumedKcal: consumedKcal ?? (resolvedPacedGoalKcal + deltaKcal),
    deltaKcal: deltaKcal,
    paceRatio: paceRatio,
    deadZoneKcal: deadZoneKcal,
    rangeKcal: rangeKcal,
    activityDeltaKcal: 0,
    usedLearnedTdee: false,
  );
}

extension on CalorieBalanceSummaryData {
  CalorieBalanceSummaryData copyWithPaceWindowStart(DateTime paceWindowStart) {
    return CalorieBalanceSummaryData(
      selectedDay: selectedDay,
      referenceNow: referenceNow,
      windowStartDate: windowStartDate,
      balanceStartDate: balanceStartDate,
      paceWindowStart: paceWindowStart,
      paceWindowEnd: paceWindowEnd,
      baseGoalKcal: baseGoalKcal,
      carryoverKcal: carryoverKcal,
      goalMode: goalMode,
      flexibleGoalKcal: flexibleGoalKcal,
      pacedGoalKcal: pacedGoalKcal,
      consumedKcal: consumedKcal,
      deltaKcal: deltaKcal,
      paceRatio: paceRatio,
      deadZoneKcal: deadZoneKcal,
      rangeKcal: rangeKcal,
      activityDeltaKcal: activityDeltaKcal,
      usedLearnedTdee: usedLearnedTdee,
    );
  }
}
