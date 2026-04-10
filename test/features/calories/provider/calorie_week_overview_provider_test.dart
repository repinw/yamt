import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

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
  test('calorieWeekOverview aggregates rolling seven-day totals', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final fourDaysAgo = today.subtract(const Duration(days: 4));
    final eightDaysAgo = today.subtract(const Duration(days: 8));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'today',
          loggedAt: today.add(const Duration(hours: 8)),
          totalKcal: 600,
        ),
        _entry(
          'four-days-ago',
          loggedAt: fourDaysAgo.add(const Duration(hours: 12)),
          totalKcal: 400,
        ),
        _entry(
          'outside-window',
          loggedAt: eightDaysAgo.add(const Duration(hours: 12)),
          totalKcal: 900,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: today.subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final overview = await container.read(calorieWeekOverviewProvider.future);

    expect(overview.days, hasLength(diaryVisibleDayCount));
    expect(overview.days.last.date, today);
    expect(overview.days.first.date, today.subtract(const Duration(days: 6)));
    expect(overview.totalConsumedKcal, 1000);
    expect(overview.totalGoalKcal, 14000);
    expect(overview.remainingKcal, 13000);
  });

  test('calorieWeekOverview keeps working when one day read throws', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final failingDay = today.subtract(const Duration(days: 2));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'today',
          loggedAt: today.add(const Duration(hours: 8)),
          totalKcal: 600,
        ),
        _entry(
          'failing-day',
          loggedAt: failingDay.add(const Duration(hours: 12)),
          totalKcal: 900,
        ),
      ],
    );
    logRepository.onReadEntriesForDay = (day) async {
      if (day == failingDay) {
        throw StateError('day read failed');
      }
      return logRepository.entries
          .where((entry) {
            final loggedAt = entry.loggedAt;
            return loggedAt.year == day.year &&
                loggedAt.month == day.month &&
                loggedAt.day == day.day;
          })
          .toList(growable: false);
    };
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: today.subtract(const Duration(days: 6)),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final overview = await container.read(calorieWeekOverviewProvider.future);

    expect(overview.days, hasLength(diaryVisibleDayCount));
    expect(
      overview.days.firstWhere((day) => day.date == failingDay).totalKcal,
      0,
    );
    expect(overview.totalConsumedKcal, 600);
    expect(overview.totalGoalKcal, 14000);
    expect(overview.remainingKcal, 13400);
  });

  test('calorieWeekOverview uses day-specific goals and resets buffer '
      'on the latest goal change', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'yesterday',
          loggedAt: yesterday.add(const Duration(hours: 8)),
          totalKcal: 2100,
        ),
        _entry(
          'today',
          loggedAt: today.add(const Duration(hours: 8)),
          totalKcal: 1700,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: threeDaysAgo,
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: yesterday,
            dailyKcalGoal: 1800,
            calculatorProfile: null,
          ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final overview = await container.read(calorieWeekOverviewProvider.future);

    expect(
      overview.days.firstWhere((day) => day.date == threeDaysAgo).goalKcal,
      2400,
    );
    expect(
      overview.days.firstWhere((day) => day.date == yesterday).goalKcal,
      1800,
    );
    expect(overview.days.firstWhere((day) => day.date == today).goalKcal, 1800);
    expect(overview.balanceStartDate, yesterday);
    expect(overview.totalConsumedKcal, 3800);
    expect(overview.totalGoalKcal, 3600);
    expect(overview.remainingKcal, -200);
    expect(overview.carryoverBeforeTodayKcal, -300);
    expect(overview.todayFlexibleGoalKcal, 1500);
  });

  test(
    'calorieWeekOverview does not reload seven days when goal resolves later',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'today',
            loggedAt: today.add(const Duration(hours: 8)),
            totalKcal: 600,
          ),
        ],
      );
      var readCount = 0;
      logRepository.onReadEntriesForDay = (day) async {
        readCount += 1;
        return logRepository.entries
            .where((entry) {
              final loggedAt = entry.loggedAt;
              return loggedAt.year == day.year &&
                  loggedAt.month == day.month &&
                  loggedAt.day == day.day;
            })
            .toList(growable: false);
      };

      final settingsRepository = _DelayedCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        calorieWeekOverviewProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final initialOverview = await container.read(
        calorieWeekOverviewProvider.future,
      );

      expect(initialOverview.totalConsumedKcal, 600);
      expect(initialOverview.totalGoalKcal, 17500);
      expect(readCount, diaryVisibleDayCount);

      final updatedOverview = Completer<CalorieWeekOverview>();
      final updatedSubscription = container.listen(
        calorieWeekOverviewProvider,
        (_, next) {
          final overview = next.asData?.value;
          if (overview == null || updatedOverview.isCompleted) {
            return;
          }
          if (overview.totalGoalKcal == 1800) {
            updatedOverview.complete(overview);
          }
        },
      );
      addTearDown(updatedSubscription.close);

      settingsRepository.emit(
        CalorieGoalSettings.single(
          dailyKcalGoal: 1800,
          calculatorProfile: null,
          effectiveDate: today,
        ),
      );

      final overview = await updatedOverview.future;
      expect(overview.totalGoalKcal, 1800);
      expect(overview.totalConsumedKcal, 600);
      expect(readCount, diaryVisibleDayCount);
    },
  );

  test('calorieWeekOverview ignores days before a future goal start', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'today',
          loggedAt: today.add(const Duration(hours: 12)),
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
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final overview = await container.read(calorieWeekOverviewProvider.future);

    expect(overview.goalStartsInFuture, isTrue);
    expect(overview.nextGoalStartDate, tomorrow);
    expect(overview.balanceStartDate, tomorrow);
    expect(overview.totalConsumedKcal, 0);
    expect(overview.totalGoalKcal, 0);
    expect(overview.remainingKcal, 0);
    expect(overview.carryoverBeforeTodayKcal, 0);
    expect(overview.todayFlexibleGoalKcal, 0);
    expect(overview.days.firstWhere((day) => day.date == today).goalKcal, 0);
  });
}

class _DelayedCalorieSettingsRepository implements CalorieSettingsRepository {
  final _controller = StreamController<CalorieGoalSettings>.broadcast();

  CalorieGoalSettings _settings = const CalorieGoalSettings.empty();

  @override
  Stream<CalorieGoalSettings> watchSettings() => _controller.stream;

  @override
  Future<CalorieGoalSettings> readSettings() async => _settings;

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    _settings = settings;
    _controller.add(settings);
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) {
    return saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        effectiveDate: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(
      const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime.now(),
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  void emit(CalorieGoalSettings settings) {
    _settings = settings;
    _controller.add(settings);
  }

  Future<void> dispose() => _controller.close();
}
