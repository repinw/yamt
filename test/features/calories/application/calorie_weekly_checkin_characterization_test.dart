import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/data/'
    'burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

// Pins the whole check-in result of two windows, so a change to the pipeline
// that moves any number shows up here.

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  const new();

  @override
  Future<BurnWeekRunState> readState() async =>
      const BurnWeekRunState.initial();

  @override
  Future<bool> saveState(BurnWeekRunState state) async => true;
}

final _goalStart = DateTime(2026, 4, 8);

CalorieEntry _entry(int index, double kcal) {
  final loggedAt = _goalStart.add(Duration(days: index, hours: 8));
  return CalorieEntry.create(
    id: 'entry-$index',
    userId: 'user-1',
    name: 'Item $index',
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

CalorieGoalSettings _firstWindowSettings() => CalorieGoalSettings.single(
  dailyKcalGoal: 2400,
  calculatorProfile: null,
  effectiveDate: _goalStart,
);

CalorieGoalSettings _secondWindowSettings() =>
    _firstWindowSettings().applyGoalChange(
      changedAt: DateTime(2026, 4, 15),
      dailyKcalGoal: 2580,
      calculatorProfile: null,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: _goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.05,
        calculatedTdeeKcal: 2580,
        lowConfidence: false,
        inputHash: 'v1:week-one',
      ),
    );

Future<CalorieWeeklyCheckInData> _build({
  required DateTime today,
  required CalorieGoalSettings settings,
  required List<CalorieEntry> entries,
  required List<ManualHealthWeightEntry> weights,
}) async {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  final logRepository = FakeCalorieLogRepository(initialEntries: entries);
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWith(
        (ref) =>
            () => today,
      ),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        const _FakeBurnWeekRunStateRepository(),
      ),
      healthConnectionServiceProvider.overrideWith(
        (ref) => FakeHealthConnectionService(
          const HealthConnectionStatus(
            platform: HealthPlatform.android,
            healthConnectAvailability: HealthConnectAvailability.available,
            permissionState: HealthPermissionState.notGranted,
            historyAccess: HealthHistoryAccess.notGranted,
          ),
        ),
      ),
      manualHealthWeightRepositoryProvider.overrideWith(
        (ref) => FakeManualHealthWeightRepository(weights),
      ),
    ],
  );
  addTearDown(container.dispose);
  return await container
      .listen(calorieWeeklyCheckInDataProvider.future, (_, _) {})
      .read();
}

String? _fixed(double? value) => value?.toStringAsFixed(6);

String _day(DateTime day) => '${day.month}-${day.day}';

Map<String, Object?> _pin(CalorieWeeklyCheckInData data) {
  final window = data.cacheWeeklyCheckIn;
  final calculation = data.calculation;
  return {
    'window': window == null
        ? null
        : '${_day(window.windowStartDate)}..${_day(window.windowEndDate)}',
    'blockedReason': data.blockedReason?.name,
    'missingIntakeDays': data.missingIntakeDays.map(_day).toList(),
    'missingWeightDays': data.missingWeightDays.map(_day).toList(),
    'lowConfidence': data.lowConfidence,
    'inputHash': data.inputHash,
    'macroWeightKg': _fixed(data.macroWeightKg),
    'trendWeightChangePerDay': _fixed(calculation?.trendWeightChangePerDay),
    'averageIntakeKcal': _fixed(calculation?.averageIntakeKcal),
    'measuredTdeeKcal': _fixed(calculation?.measuredTdeeKcal),
    'calculatedTdeeKcal': _fixed(calculation?.calculatedTdeeKcal),
    'previousTdeeKcal': _fixed(calculation?.previousTdeeKcal),
    'previousGoalKcal': _fixed(calculation?.previousGoalKcal),
    'newGoalKcal': _fixed(calculation?.newGoalKcal),
    'dynamicGoalTodayKcal': _fixed(calculation?.dynamicGoalTodayKcal),
    // Day, logged, resolved, weight, skipped, pause.
    'days': [
      for (final day in data.days)
        [
          _day(day.day),
          _fixed(day.loggedIntakeKcal),
          _fixed(day.resolvedIntakeKcal),
          _fixed(day.weightKg),
          day.isSkippedIntakeDay,
          day.isPauseDay,
        ].join(' '),
    ],
  };
}

void main() {
  test('the first window', () async {
    final data = await _build(
      today: DateTime(2026, 4, 15),
      settings: _firstWindowSettings(),
      entries: [for (var index = 0; index < 7; index++) _entry(index, 2100)],
      weights: [
        ManualHealthWeightEntry(day: _goalStart, weightKg: 82),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 11), weightKg: 81.8),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 14), weightKg: 81.4),
      ],
    );

    expect(_pin(data), <String, Object?>{
      'window': '4-8..4-14',
      'blockedReason': null,
      'missingIntakeDays': [],
      'missingWeightDays': [],
      'lowConfidence': false,
      'inputHash': 'v3:d0793914',
      'macroWeightKg': '81.843735',
      'trendWeightChangePerDay': '-0.011115',
      'averageIntakeKcal': '2100.000000',
      'measuredTdeeKcal': '2185.585500',
      'calculatedTdeeKcal': '2171.204992',
      'previousTdeeKcal': '2400.000000',
      'previousGoalKcal': '2400.000000',
      'newGoalKcal': '2200.000000',
      'dynamicGoalTodayKcal': '2200.000000',
      'days': [
        '4-8 2100.000000 2100.000000 82.000000 false false',
        '4-9 2100.000000 2100.000000 null false false',
        '4-10 2100.000000 2100.000000 null false false',
        '4-11 2100.000000 2100.000000 81.800000 false false',
        '4-12 2100.000000 2100.000000 null false false',
        '4-13 2100.000000 2100.000000 null false false',
        '4-14 2100.000000 2100.000000 81.400000 false false',
      ],
    });
  });

  test('the second window', () async {
    final data = await _build(
      today: DateTime(2026, 4, 22),
      settings: _secondWindowSettings(),
      entries: [
        for (var index = 0; index < 14; index++)
          if (index != 16 - 8) _entry(index, 2900 + index * 15),
      ],
      weights: [
        ManualHealthWeightEntry(day: _goalStart, weightKg: 82),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 14), weightKg: 81.5),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 18), weightKg: 81.2),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 21), weightKg: 81),
      ],
    );

    expect(_pin(data), <String, Object?>{
      'window': '4-15..4-21',
      'blockedReason': null,
      'missingIntakeDays': ['4-16'],
      'missingWeightDays': [],
      'lowConfidence': false,
      'inputHash': 'v3:a10fae0b',
      'macroWeightKg': '81.499907',
      'trendWeightChangePerDay': '-0.026658',
      'averageIntakeKcal': '3055.000000',
      'measuredTdeeKcal': '3260.269488',
      'calculatedTdeeKcal': '3219.519687',
      'previousTdeeKcal': '2952.642710',
      'previousGoalKcal': '3122.114149',
      'newGoalKcal': '3219.519687',
      'dynamicGoalTodayKcal': '3219.519687',
      'days': [
        '4-15 3005.000000 3005.000000 81.500000 false false',
        '4-16 0.000000 3055.000000 null true false',
        '4-17 3035.000000 3035.000000 null false false',
        '4-18 3050.000000 3050.000000 81.200000 false false',
        '4-19 3065.000000 3065.000000 null false false',
        '4-20 3080.000000 3080.000000 null false false',
        '4-21 3095.000000 3095.000000 81.000000 false false',
      ],
    });
  });

  test('the second window with one weigh-in', () async {
    final data = await _build(
      today: DateTime(2026, 4, 22),
      settings: _secondWindowSettings(),
      entries: [for (var index = 0; index < 14; index++) _entry(index, 2900)],
      weights: [ManualHealthWeightEntry(day: _goalStart, weightKg: 82)],
    );

    expect(_pin(data), <String, Object?>{
      'window': '4-15..4-21',
      'blockedReason': 'missingWindowEndWeight',
      'missingIntakeDays': [],
      'missingWeightDays': ['4-21'],
      'lowConfidence': false,
      'inputHash': null,
      'macroWeightKg': null,
      'trendWeightChangePerDay': null,
      'averageIntakeKcal': null,
      'measuredTdeeKcal': null,
      'calculatedTdeeKcal': null,
      'previousTdeeKcal': null,
      'previousGoalKcal': null,
      'newGoalKcal': null,
      'dynamicGoalTodayKcal': null,
      'days': [
        '4-15 2900.000000 2900.000000 null false false',
        '4-16 2900.000000 2900.000000 null false false',
        '4-17 2900.000000 2900.000000 null false false',
        '4-18 2900.000000 2900.000000 null false false',
        '4-19 2900.000000 2900.000000 null false false',
        '4-20 2900.000000 2900.000000 null false false',
        '4-21 2900.000000 2900.000000 null false false',
      ],
    });
  });

  test('the second window with weigh-ins only before it', () async {
    final data = await _build(
      today: DateTime(2026, 4, 22),
      settings: _secondWindowSettings(),
      entries: [for (var index = 0; index < 14; index++) _entry(index, 2900)],
      weights: [
        ManualHealthWeightEntry(day: _goalStart, weightKg: 82),
        ManualHealthWeightEntry(day: DateTime(2026, 4, 10), weightKg: 81.8),
      ],
    );

    expect(_pin(data), <String, Object?>{
      'window': '4-15..4-21',
      'blockedReason': null,
      'missingIntakeDays': [],
      'missingWeightDays': [],
      'lowConfidence': true,
      'inputHash': 'v3:3b3dd682',
      'macroWeightKg': '81.971000',
      'trendWeightChangePerDay': '-0.003000',
      'averageIntakeKcal': '2900.000000',
      'measuredTdeeKcal': '2923.100000',
      'calculatedTdeeKcal': '2923.100000',
      'previousTdeeKcal': '2906.139406',
      'previousGoalKcal': '2923.073799',
      'newGoalKcal': '2923.100000',
      'dynamicGoalTodayKcal': '2923.100000',
      'days': [
        '4-15 2900.000000 2900.000000 null false false',
        '4-16 2900.000000 2900.000000 null false false',
        '4-17 2900.000000 2900.000000 null false false',
        '4-18 2900.000000 2900.000000 null false false',
        '4-19 2900.000000 2900.000000 null false false',
        '4-20 2900.000000 2900.000000 null false false',
        '4-21 2900.000000 2900.000000 null false false',
      ],
    });
  });
}
