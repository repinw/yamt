import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

CalorieEntry _entry(String id, DateTime loggedAt, double kcal) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
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

List<CalorieEntry> _dailyEntries({
  required DateTime startDay,
  required int count,
  required double Function(int index) kcalForIndex,
}) {
  return <CalorieEntry>[
    for (var index = 0; index < count; index += 1)
      _entry(
        'entry-$index',
        startDay.add(Duration(days: index, hours: 8)),
        kcalForIndex(index),
      ),
  ];
}

List<HealthWeightSample> _stableBoundaryWeights({
  required DateTime startDay,
  required int boundaryCount,
  double weightKg = 80,
}) {
  return <HealthWeightSample>[
    for (var index = 0; index <= boundaryCount; index += 1)
      HealthWeightSample(
        recordedAt: startDay.add(
          Duration(days: index * weeklyCheckInWindowLengthDays),
        ),
        weightKg: weightKg,
      ),
  ];
}

CalorieGoalSettings _baseSettings({
  required DateTime startDay,
  double dailyGoalKcal = 2400,
}) {
  return const CalorieGoalSettings.empty().applyGoalChange(
    changedAt: startDay,
    dailyKcalGoal: dailyGoalKcal,
    calculatorProfile: null,
  );
}

CalorieGoalSettings _learnedSettings({
  required DateTime startDay,
  required DateTime windowEndDate,
  double dailyGoalKcal = 2400,
  double learnedTdeeKcal = 2400,
}) {
  return _baseSettings(
    startDay: startDay,
    dailyGoalKcal: dailyGoalKcal,
  ).applyGoalChange(
    changedAt: nextDiaryDay(windowEndDate),
    dailyKcalGoal: dailyGoalKcal,
    calculatorProfile: null,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: startDay,
      windowEndDate: windowEndDate,
      trendWeightChangePerDay: 0,
      calculatedTrueTdeeKcal: learnedTdeeKcal,
      averageActiveKcal: 0,
      lowConfidence: false,
    ),
  );
}

class _DailyLearnedHarness {
  _DailyLearnedHarness({
    required CalorieGoalSettings settings,
    required List<CalorieEntry> entries,
    required List<HealthWeightSample> healthWeights,
    List<ManualHealthWeightEntry> manualWeights =
        const <ManualHealthWeightEntry>[],
  }) {
    logRepository = FakeCalorieLogRepository(initialEntries: entries);
    settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: settings,
    );
    manualRepository = FakeManualHealthWeightRepository(manualWeights);
    container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_readyStatus),
        ),
        diaryHealthServiceProvider.overrideWith(
          (ref) => FakeDiaryHealthService(
            const <String, DiaryHealthDayData>{},
          ),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(healthWeights),
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => manualRepository,
        ),
      ],
    );
  }

  late final ProviderContainer container;
  late final FakeCalorieLogRepository logRepository;
  late final FakeCalorieSettingsRepository settingsRepository;
  late final FakeManualHealthWeightRepository manualRepository;

  Future<void> dispose() async {
    container.dispose();
    await logRepository.dispose();
    await settingsRepository.dispose();
  }
}

Future<DailyLearnedTdeeGoalData?> _readDailyLearned(
  ProviderContainer container, {
  required DateTime today,
  DateTime? day,
  double storedGoalKcal = 2400,
}) {
  return container.read(
    dailyLearnedTdeeGoalForDayProvider(
      day: day ?? today,
      today: today,
      storedGoalKcal: storedGoalKcal,
    ).future,
  );
}

void main() {
  test('calculates learned TDEE from 28 complete intake days', () async {
    final startDay = DateTime(2026, 4);
    final today = startDay.add(
      const Duration(days: dailyLearnedTdeeMaximumLookbackDays),
    );
    final harness = _DailyLearnedHarness(
      settings: _learnedSettings(
        startDay: startDay,
        windowEndDate: startDay.add(const Duration(days: 6)),
      ),
      entries: _dailyEntries(
        startDay: startDay,
        count: dailyLearnedTdeeMaximumLookbackDays,
        kcalForIndex: (_) => 2500,
      ),
      healthWeights: _stableBoundaryWeights(
        startDay: startDay,
        boundaryCount: 4,
      ),
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(harness.container, today: today);

    expect(result, isNotNull);
    expect(result!.measured.averageIntakeKcal, closeTo(2500, 0.01));
    expect(result.measured.trendWeightChangePerDay, closeTo(0, 0.00001));
    expect(result.measured.measuredTrueTdeeKcal, closeTo(2500, 0.01));
    expect(result.calculatedTrueTdeeKcal, closeTo(2475.99, 0.01));
    expect(result.newGoalKcal, closeTo(2475.99, 0.01));
  });

  test(
    'uses median health weight for odd and even daily sample counts',
    () async {
      final startDay = DateTime(2026, 4);
      final firstDueDate = startDay.add(
        const Duration(days: weeklyCheckInWindowLengthDays),
      );
      final today = startDay.add(
        const Duration(days: dailyLearnedTdeeMinimumCompleteDays),
      );
      final harness = _DailyLearnedHarness(
        settings: _learnedSettings(
          startDay: startDay,
          windowEndDate: startDay.add(const Duration(days: 6)),
        ),
        entries: _dailyEntries(
          startDay: startDay,
          count: dailyLearnedTdeeMinimumCompleteDays,
          kcalForIndex: (_) => 2500,
        ),
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 70),
          HealthWeightSample(
            recordedAt: startDay.add(const Duration(hours: 1)),
            weightKg: 80,
          ),
          HealthWeightSample(
            recordedAt: startDay.add(const Duration(hours: 2)),
            weightKg: 200,
          ),
          HealthWeightSample(recordedAt: firstDueDate, weightKg: 70),
          HealthWeightSample(
            recordedAt: firstDueDate.add(const Duration(hours: 1)),
            weightKg: 90,
          ),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNotNull);
      expect(result!.measured.trendWeightChangePerDay, closeTo(0, 0.00001));
      expect(result.measured.measuredTrueTdeeKcal, closeTo(2500, 0.01));
      expect(result.newGoalKcal, closeTo(2430, 0.01));
    },
  );

  test(
    'returns null before minimum complete intake days are available',
    () async {
      final startDay = DateTime(2026, 4);
      final today = startDay.add(
        const Duration(days: weeklyCheckInWindowLengthDays - 1),
      );
      final harness = _DailyLearnedHarness(
        settings: _learnedSettings(
          startDay: startDay,
          windowEndDate: startDay.add(const Duration(days: 5)),
        ),
        entries: _dailyEntries(
          startDay: startDay,
          count: weeklyCheckInWindowLengthDays - 1,
          kcalForIndex: (_) => 2500,
        ),
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: today, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNull);
    },
  );

  test('returns null when fewer than two weight points exist', () async {
    final startDay = DateTime(2026, 4);
    final today = startDay.add(
      const Duration(days: dailyLearnedTdeeMinimumCompleteDays),
    );
    final harness = _DailyLearnedHarness(
      settings: _baseSettings(startDay: startDay),
      entries: _dailyEntries(
        startDay: startDay,
        count: dailyLearnedTdeeMinimumCompleteDays,
        kcalForIndex: (_) => 2500,
      ),
      healthWeights: <HealthWeightSample>[
        HealthWeightSample(recordedAt: startDay, weightKg: 80),
      ],
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(harness.container, today: today);

    expect(result, isNull);
  });

  test(
    'uses saved learned target when saved window now misses end weight',
    () async {
      final startDay = DateTime(2026, 4);
      final today = startDay.add(
        const Duration(days: weeklyCheckInWindowLengthDays),
      );
      final settings = _learnedSettings(
        startDay: startDay,
        windowEndDate: today.subtract(const Duration(days: 1)),
        dailyGoalKcal: 2580,
        learnedTdeeKcal: 2580,
      );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: _dailyEntries(
          startDay: startDay,
          count: weeklyCheckInWindowLengthDays,
          kcalForIndex: (_) => 2580,
        ),
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNotNull);
      expect(result!.calculatedTrueTdeeKcal, closeTo(2580, 0.01));
      expect(result.newGoalKcal, closeTo(2580, 0.01));
    },
  );

  test(
    'keeps latest learned target when current window misses end weight',
    () async {
      final startDay = DateTime(2026, 4);
      final weekTwoStart = startDay.add(
        const Duration(days: weeklyCheckInWindowLengthDays),
      );
      final today = weekTwoStart.add(
        const Duration(days: weeklyCheckInWindowLengthDays),
      );
      final settings = _learnedSettings(
        startDay: startDay,
        windowEndDate: weekTwoStart.subtract(const Duration(days: 1)),
        dailyGoalKcal: 2580,
        learnedTdeeKcal: 2580,
      );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: _dailyEntries(
          startDay: startDay,
          count: weeklyCheckInWindowLengthDays * 2,
          kcalForIndex: (index) =>
              index < weeklyCheckInWindowLengthDays ? 2580 : 3000,
        ),
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: weekTwoStart, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNotNull);
      expect(result!.calculatedTrueTdeeKcal, greaterThan(0));
      expect(result.newGoalKcal, greaterThan(0));
    },
  );

  test('uses latest completed learned target for future days', () async {
    final startDay = DateTime(2026, 4, 8);
    final today = DateTime(2026, 4, 15);
    final futureDay = DateTime(2026, 4, 16);
    final harness = _DailyLearnedHarness(
      settings: _baseSettings(startDay: startDay),
      entries: _dailyEntries(
        startDay: startDay,
        count: weeklyCheckInWindowLengthDays,
        kcalForIndex: (_) => 3000,
      ),
      healthWeights: <HealthWeightSample>[
        HealthWeightSample(recordedAt: startDay, weightKg: 80),
        HealthWeightSample(recordedAt: today, weightKg: 80),
      ],
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(
      harness.container,
      day: futureDay,
      today: today,
    );

    expect(result, isNotNull);
    expect(result!.measured.averageIntakeKcal, closeTo(3000, 0.01));
    expect(result.calculatedTrueTdeeKcal, closeTo(2580, 0.01));
    expect(result.newGoalKcal, closeTo(2580, 0.01));
  });

  test(
    'ignores stale learned snapshot when source intake is invalid',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final today = DateTime(2026, 4, 15);
      final settings = _learnedSettings(
        startDay: startDay,
        windowEndDate: DateTime(2026, 4, 14),
        dailyGoalKcal: 2580,
        learnedTdeeKcal: 2580,
      );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: <CalorieEntry>[
          for (var index = 1; index < weeklyCheckInWindowLengthDays; index += 1)
            _entry(
              'entry-$index',
              startDay.add(Duration(days: index, hours: 8)),
              3000,
            ),
        ],
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: today, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNull);
    },
  );

  test(
    'ignores stale learned snapshot when source intake is removed',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final today = DateTime(2026, 4, 15);
      final settings = _learnedSettings(
        startDay: startDay,
        windowEndDate: DateTime(2026, 4, 14),
        dailyGoalKcal: 2580,
        learnedTdeeKcal: 2580,
      );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: const <CalorieEntry>[],
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: today, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNull);
    },
  );

  test(
    'invalidates later learned snapshot when earlier source window changes',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final weekTwoStart = DateTime(2026, 4, 15);
      final today = DateTime(2026, 4, 22);
      final settings = _baseSettings(startDay: startDay)
          .applyGoalChange(
            changedAt: weekTwoStart,
            dailyKcalGoal: 2580,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: startDay,
              windowEndDate: DateTime(2026, 4, 14),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2580,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2650,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: weekTwoStart,
              windowEndDate: DateTime(2026, 4, 21),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2650,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: <CalorieEntry>[
          for (var index = 1; index < 14; index += 1)
            _entry(
              'entry-$index',
              startDay.add(Duration(days: index, hours: 8)),
              3000,
            ),
        ],
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: weekTwoStart, weightKg: 80),
          HealthWeightSample(recordedAt: today, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNull);
    },
  );

  test(
    'does not let dirty learned snapshot block legacy fallback',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final weekTwoStart = DateTime(2026, 4, 15);
      final today = DateTime(2026, 4, 22);
      final settings = _baseSettings(startDay: startDay)
          .applyGoalChange(
            changedAt: weekTwoStart,
            dailyKcalGoal: 2580,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: startDay,
              windowEndDate: DateTime(2026, 4, 14),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2580,
              averageActiveKcal: 0,
              lowConfidence: false,
              invalidatedAt: DateTime(2026, 4, 20),
            ),
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2650,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: weekTwoStart,
              windowEndDate: DateTime(2026, 4, 21),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2650,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );
      final harness = _DailyLearnedHarness(
        settings: settings,
        entries: _dailyEntries(
          startDay: weekTwoStart,
          count: weeklyCheckInWindowLengthDays,
          kcalForIndex: (_) => 2600,
        ),
        healthWeights: <HealthWeightSample>[
          HealthWeightSample(recordedAt: startDay, weightKg: 80),
          HealthWeightSample(recordedAt: weekTwoStart, weightKg: 80),
          HealthWeightSample(recordedAt: today, weightKg: 80),
        ],
      );
      addTearDown(harness.dispose);

      final result = await _readDailyLearned(harness.container, today: today);

      expect(result, isNotNull);
      expect(result!.calculatedTrueTdeeKcal, 2650);
    },
  );

  test('seeds same-day learned goal from anchor snapshot', () async {
    final startDay = DateTime(2026, 4, 8);
    final today = DateTime(2026, 4, 15);
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2700,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 120,
        heightCm: 190,
        ageYears: 30,
        activityLevel: 1.9,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      ),
      effectiveDate: startDay,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4),
        windowEndDate: DateTime(2026, 4, 7),
        trendWeightChangePerDay: 0,
        calculatedTrueTdeeKcal: 2700,
        averageActiveKcal: 0,
        lowConfidence: false,
      ),
    );
    final harness = _DailyLearnedHarness(
      settings: settings,
      entries: _dailyEntries(
        startDay: startDay,
        count: weeklyCheckInWindowLengthDays,
        kcalForIndex: (_) => 2700,
      ),
      healthWeights: <HealthWeightSample>[
        HealthWeightSample(recordedAt: startDay, weightKg: 80),
        HealthWeightSample(recordedAt: today, weightKg: 80),
      ],
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(
      harness.container,
      today: today,
      storedGoalKcal: 2700,
    );

    expect(result, isNotNull);
    expect(result!.calculatedTrueTdeeKcal, closeTo(2700, 0.01));
    expect(result.newGoalKcal, closeTo(2700, 0.01));
  });

  test('uses real starter-day weight before calculator fallback', () async {
    final goalStart = DateTime(2026, 4, 8, 18);
    final firstCountedDay = DateTime(2026, 4, 9);
    final today = DateTime(2026, 4, 15);
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: goalStart,
      dailyKcalGoal: 2400,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 90,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      ),
      source: CalorieGoalSource.calculator,
    );
    final harness = _DailyLearnedHarness(
      settings: settings,
      entries: _dailyEntries(
        startDay: firstCountedDay,
        count: weeklyCheckInWindowLengthDays - 1,
        kcalForIndex: (_) => 2500,
      ),
      healthWeights: <HealthWeightSample>[
        HealthWeightSample(recordedAt: DateTime(2026, 4, 8, 7), weightKg: 80),
        HealthWeightSample(recordedAt: DateTime(2026, 4, 15, 7), weightKg: 78),
      ],
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(harness.container, today: today);

    expect(result, isNotNull);
    expect(
      result!.measured.trendWeightChangePerDay,
      closeTo(-0.33333, 0.00001),
    );
    expect(result.measured.measuredTrueTdeeKcal, closeTo(4833.33, 0.01));
  });

  test('interpolates skipped intake days from prior average', () async {
    final startDay = DateTime(2026, 4);
    final today = startDay.add(const Duration(days: 9));
    final skippedDay = startDay.add(const Duration(days: 1));
    final settings = _learnedSettings(
      startDay: startDay,
      windowEndDate: startDay.add(const Duration(days: 6)),
    ).setSkippedIntakeDay(day: skippedDay, isSkipped: true);
    final harness = _DailyLearnedHarness(
      settings: settings,
      entries: <CalorieEntry>[
        _entry('entry-0', startDay.add(const Duration(hours: 8)), 2000),
        for (var index = 2; index < 9; index += 1)
          _entry(
            'entry-$index',
            startDay.add(Duration(days: index, hours: 8)),
            2500,
          ),
      ],
      healthWeights: <HealthWeightSample>[
        HealthWeightSample(recordedAt: startDay, weightKg: 80),
        HealthWeightSample(
          recordedAt: startDay.add(
            const Duration(days: weeklyCheckInWindowLengthDays),
          ),
          weightKg: 80,
        ),
      ],
    );
    addTearDown(harness.dispose);

    final result = await _readDailyLearned(harness.container, today: today);

    expect(result, isNotNull);
    expect(result!.measured.averageIntakeKcal, closeTo(2357.14, 0.01));
    expect(result.calculatedTrueTdeeKcal, closeTo(2387.14, 0.01));
    expect(result.newGoalKcal, closeTo(2387.14, 0.01));
  });
}
