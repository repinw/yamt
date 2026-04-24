import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
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

  test(
    'statisticsCalorieDataProvider excludes future-start practice day',
    () async {
      final today = _dateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));
      final repository = _RecordingCalorieLogRepository(
        initialEntries: [
          _entry('practice-entry', today.add(const Duration(hours: 12))),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: today,
          countingStartDate: tomorrow,
          source: CalorieGoalSource.calculator,
        ),
      );
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);
      final snapshot = await container.read(
        statisticsCalorieDataProvider(StatisticsTimeframe.total).future,
      );

      expect(snapshot.days, isEmpty);
      expect(snapshot.totalEntries, 0);
      expect(snapshot.trackedDayCount, 0);
      expect(snapshot.averageTrackedKcal, 0);
    },
  );

  test(
    'statisticsCalorieDataProvider excludes future-effective practice day',
    () async {
      final today = _dateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));
      final repository = _RecordingCalorieLogRepository(
        initialEntries: [
          _entry('practice-entry', today.add(const Duration(hours: 12))),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: tomorrow,
          countingStartDate: tomorrow,
          source: CalorieGoalSource.calculator,
        ),
      );
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);
      final snapshot = await container.read(
        statisticsCalorieDataProvider(StatisticsTimeframe.total).future,
      );

      expect(snapshot.days, isEmpty);
      expect(snapshot.totalEntries, 0);
      expect(snapshot.trackedDayCount, 0);
      expect(snapshot.averageTrackedKcal, 0);
    },
  );

  test('statisticsCalorieDataProvider includes same-day quick start', () async {
    final today = _dateOnly(DateTime.now());
    final repository = _RecordingCalorieLogRepository(
      initialEntries: [
        _entry('quick-start-entry', today.add(const Duration(hours: 12))),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: null,
        effectiveDate: today.add(const Duration(hours: 12)),
        source: CalorieGoalSource.calculator,
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

    expect(snapshot.days, hasLength(1));
    expect(snapshot.totalEntries, 1);
    expect(snapshot.trackedDayCount, 1);
    expect(snapshot.averageTrackedKcal, 500);
  });
}

class _RecordingCalorieLogRepository extends FakeCalorieLogRepository {
  _RecordingCalorieLogRepository({super.initialEntries});

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

CalorieEntry _entry(String id, DateTime loggedAt) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Entry $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 500,
    per100Protein: 20,
    per100Carbs: 50,
    per100Fat: 15,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void _expectSameDay(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(_dateOnly(actual!), _dateOnly(expected));
}
