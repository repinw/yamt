import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/provider/statistics_calorie_data_provider.dart';

import '../../calories/support/fake_calories_repositories.dart';

void main() {
  test('statisticsCalorieDataProvider uses trailing seven-day fallback '
      'when entry date and goal history are missing', () async {
    final today = DateTime.now();
    final repository = _RecordingCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty(),
    );
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final snapshot = await container.read(
      statisticsCalorieDataProvider(StatisticsTimeframe.total).future,
    );

    final normalizedToday = _dateOnly(today);
    _expectSameDay(
      repository.lastStartInclusive,
      normalizedToday.subtract(const Duration(days: 6)),
    );
    _expectSameDay(
      repository.lastEndExclusive,
      normalizedToday.add(const Duration(days: 1)),
    );
    expect(snapshot.days, hasLength(7));
  });

  test('statisticsCalorieDataProvider uses earliest goal history day '
      'when first entry date is missing', () async {
    final today = DateTime.now();
    final historyStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 21));
    final repository = _RecordingCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: null,
        effectiveDate: historyStart,
      ),
    );
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final snapshot = await container.read(
      statisticsCalorieDataProvider(StatisticsTimeframe.total).future,
    );

    _expectSameDay(repository.lastStartInclusive, historyStart);
    _expectSameDay(snapshot.days.first.date, historyStart);
  });
}

class _RecordingCalorieLogRepository extends FakeCalorieLogRepository {
  DateTime? lastStartInclusive;
  DateTime? lastEndExclusive;

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    lastStartInclusive = startInclusive;
    lastEndExclusive = endExclusive;
    return super.readEntriesInRange(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

void _expectSameDay(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(_dateOnly(actual!), _dateOnly(expected));
}
