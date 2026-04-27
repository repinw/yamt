import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';

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
  double storedGoalKcal = 2400,
}) {
  return container.read(
    dailyLearnedTdeeGoalForDayProvider(
      day: today,
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
