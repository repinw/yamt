import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_week_overview_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

import '../support/fake_calories_repositories.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  const _FakeBurnWeekRunStateRepository(this.state);

  final BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState state) async => true;
}

const _readyHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

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

Future<List<CalorieEntry>> _readLogEntriesInRange(
  FakeCalorieLogRepository logRepository, {
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  return Future.value(
    logRepository.entries
        .where((entry) {
          final loggedAt = entry.loggedAt;
          return !loggedAt.isBefore(startInclusive) &&
              loggedAt.isBefore(endExclusive);
        })
        .toList(growable: false),
  );
}

Future<List<CalorieEntry>> _readLogEntriesForDay(
  FakeCalorieLogRepository logRepository,
  DateTime day,
) {
  return Future.value(
    logRepository.entries
        .where((entry) {
          final loggedAt = entry.loggedAt;
          return loggedAt.year == day.year &&
              loggedAt.month == day.month &&
              loggedAt.day == day.day;
        })
        .toList(growable: false),
  );
}

void main() {
  test('CalorieWeekDayOverview getters report entry state', () {
    final withinGoal = CalorieWeekDayOverview(
      date: DateTime(2026, 3, 20),
      totalKcal: 1800,
      goalKcal: 2200,
      entryCount: 1,
    );
    final overGoal = CalorieWeekDayOverview(
      date: DateTime(2026, 3, 20),
      totalKcal: 2500,
      goalKcal: 2200,
      entryCount: 1,
    );
    final empty = CalorieWeekDayOverview(
      date: DateTime(2026, 3, 20),
      totalKcal: 0,
      goalKcal: 2200,
      entryCount: 0,
    );

    expect(withinGoal.hasEntries, isTrue);
    expect(withinGoal.isWithinGoal, isTrue);
    expect(overGoal.isOverGoal, isTrue);
    expect(empty.isWithinGoal, isFalse);
  });

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

  test('calorieWeekOverview treats heart day as goal-perfect', () async {
    final today = DateTime(2026, 4, 10);
    final firstVisibleDay = today.subtract(const Duration(days: 6));
    final heartDay = DateTime(2026, 4, 8);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var index = 0; index < 6; index += 1)
          _entry(
            'entry-$index',
            loggedAt: firstVisibleDay.add(Duration(days: index, hours: 8)),
            totalKcal: index == 4 ? 5000 : 2000,
          ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: firstVisibleDay,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          _FakeBurnWeekRunStateRepository(
            const BurnWeekRunState.initial().copyWith(
              heartDayKeys: <String>['2026-4-8'],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    await container.read(burnWeekRunControllerProvider.future);
    final overview = await container.read(
      calorieWeekOverviewForWindowProvider(today).future,
    );

    final heartOverview = overview.days.firstWhere(
      (day) => day.date == heartDay,
    );
    expect(heartOverview.isHeartDay, isTrue);
    expect(heartOverview.totalKcal, 5000);
    expect(heartOverview.countedTotalKcal, 2000);
    expect(heartOverview.isWithinGoal, isTrue);
    expect(heartOverview.isOverGoal, isFalse);
    expect(overview.totalConsumedKcal, 12000);
    expect(overview.carryoverBeforeTodayKcal, 0);
  });

  test(
    'calorieWeekOverview includes past activity bonus in spread carryover',
    () async {
      final today = DateTime(2026, 4, 10);
      final yesterday = today.subtract(const Duration(days: 1));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'yesterday',
            loggedAt: yesterday.add(const Duration(hours: 12)),
            totalKcal: 1500,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: yesterday,
          expectedActivityKcal: 0,
          activityTrackingStartDate: yesterday,
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
          healthConnectionServiceProvider.overrideWith(
            (ref) => FakeHealthConnectionService(_readyHealthStatus),
          ),
          diaryHealthServiceProvider.overrideWith(
            (ref) => FakeDiaryHealthService(
              <String, DiaryHealthDayData>{
                diaryDayKey(yesterday): DiaryHealthDayData(
                  totalSteps: 0,
                  workouts: <HealthWorkoutSession>[
                    HealthWorkoutSession(
                      id: 'run-1',
                      start: yesterday.add(const Duration(hours: 8)),
                      endExclusive: yesterday.add(const Duration(hours: 9)),
                      durationMinutes: 60,
                      activityLabel: 'Run',
                      sourceName: 'Health',
                      totalCalories: 1000,
                      totalSteps: 0,
                    ),
                  ],
                ),
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final provider = calorieWeekOverviewForWindowProvider(today);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final overview = await container.read(provider.future);

      expect(overview.carryoverBeforeTodayKcal, closeTo(166.667, 0.001));
      expect(overview.todayFlexibleGoalKcal, closeTo(2166.667, 0.001));
    },
  );

  test(
    'calorieWeekOverview anchors the visible window to window controller',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final selectedDay = today.subtract(const Duration(days: 1));
      final firstVisibleDay = selectedDay.subtract(const Duration(days: 6));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'selected-day',
            loggedAt: selectedDay.add(const Duration(hours: 8)),
            totalKcal: 600,
          ),
          _entry(
            'first-visible-day',
            loggedAt: firstVisibleDay.add(const Duration(hours: 12)),
            totalKcal: 400,
          ),
          _entry(
            'outside-window',
            loggedAt: today.add(const Duration(hours: 12)),
            totalKcal: 900,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: firstVisibleDay,
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
        ],
      );
      addTearDown(container.dispose);

      container.read(calorieDayControllerProvider.notifier).setDay(selectedDay);
      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(selectedDay);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(calorieWeekOverviewProvider.future);

      expect(overview.days, hasLength(diaryVisibleDayCount));
      expect(overview.days.last.date, selectedDay);
      expect(overview.days.first.date, firstVisibleDay);
      expect(overview.totalConsumedKcal, 1000);
    },
  );

  test(
    'calorieWeekOverview does not shift visible window '
    'when only selected day changes',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      final firstVisibleDay = today.subtract(const Duration(days: 6));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'today',
            loggedAt: today.add(const Duration(hours: 8)),
            totalKcal: 600,
          ),
          _entry(
            'first-visible-day',
            loggedAt: firstVisibleDay.add(const Duration(hours: 12)),
            totalKcal: 400,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: firstVisibleDay,
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
        ],
      );
      addTearDown(container.dispose);

      container.read(calorieDayControllerProvider.notifier).setDay(yesterday);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(calorieWeekOverviewProvider.future);

      expect(overview.days.last.date, today);
      expect(overview.days.first.date, firstVisibleDay);
    },
  );

  test(
    'calorieWeekOverview falls back when visible range read throws',
    () async {
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
      logRepository
        ..onReadEntriesInRange = (startInclusive, endExclusive) async {
          throw StateError('range read failed');
        }
        ..onReadEntriesForDay = (day) async {
          if (day == failingDay) {
            throw StateError('day read failed');
          }
          return _readLogEntriesForDay(logRepository, day);
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
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
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
      expect(overview.totalGoalKcal, 6000);
      expect(overview.remainingKcal, 5400);
    },
  );

  test(
    'calorieWeekConsumptionSnapshot follows visible window controller',
    () async {
      final windowEnd = DateTime(2026, 3, 20);
      final firstVisibleDay = windowEnd.subtract(const Duration(days: 6));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'first-visible',
            loggedAt: firstVisibleDay.add(const Duration(hours: 8)),
            totalKcal: 400,
          ),
          _entry(
            'window-end',
            loggedAt: windowEnd.add(const Duration(hours: 12)),
            totalKcal: 600,
          ),
        ],
      );
      var rangeReadCount = 0;
      var dayReadCount = 0;
      logRepository
        ..onReadEntriesInRange = (startInclusive, endExclusive) {
          rangeReadCount += 1;
          return _readLogEntriesInRange(
            logRepository,
            startInclusive: startInclusive,
            endExclusive: endExclusive,
          );
        }
        ..onReadEntriesForDay = (day) async {
          dayReadCount += 1;
          return const <CalorieEntry>[];
        };
      final settingsRepository = FakeCalorieSettingsRepository();
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

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(windowEnd);

      final snapshot = await container.read(
        calorieWeekConsumptionSnapshotProvider.future,
      );

      expect(snapshot.days.first.date, firstVisibleDay);
      expect(snapshot.days.last.date, windowEnd);
      expect(snapshot.totalConsumedKcal, 1000);
      expect(rangeReadCount, 1);
      expect(dayReadCount, 0);
    },
  );

  test(
    'calorieWeekDayOverviewForDate returns normalized day overview',
    () async {
      final day = DateTime(2026, 3, 20, 18, 45);
      final normalizedDay = DateTime(2026, 3, 20);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'day-entry',
            loggedAt: normalizedDay.add(const Duration(hours: 8)),
            totalKcal: 750,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: normalizedDay,
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
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(
        calorieWeekDayOverviewForDateProvider(day).future,
      );

      expect(overview.date, normalizedDay);
      expect(overview.totalKcal, 750);
      expect(overview.goalKcal, 2100);
      expect(overview.entryCount, 1);
    },
  );

  test(
    'cached day and week overviews refresh after past-day diary mutation',
    () async {
      final windowEnd = DateTime(2026, 3, 20);
      final mutatedDay = DateTime(2026, 3, 18);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'existing',
            loggedAt: mutatedDay.add(const Duration(hours: 8)),
            totalKcal: 400,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: windowEnd.subtract(const Duration(days: 6)),
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
        ],
      );
      addTearDown(container.dispose);

      container.read(calorieDayControllerProvider.notifier).setDay(windowEnd);
      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(windowEnd);
      await container.read(calorieGoalControllerProvider.future);
      await container.read(calorieEntriesControllerProvider.future);

      final initialDayOverview = await container.read(
        calorieWeekDayOverviewForDateProvider(mutatedDay).future,
      );
      final initialWeekOverview = await container.read(
        calorieWeekOverviewProvider.future,
      );

      expect(initialDayOverview.totalKcal, 400);
      expect(initialWeekOverview.totalConsumedKcal, 400);

      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(
            _entry(
              'new-entry',
              loggedAt: mutatedDay.add(const Duration(hours: 12)),
              totalKcal: 500,
            ),
          );

      expect(saved, isTrue);

      final updatedDayOverview = await container.read(
        calorieWeekDayOverviewForDateProvider(mutatedDay).future,
      );
      final updatedWeekOverview = await container.read(
        calorieWeekOverviewProvider.future,
      );

      expect(updatedDayOverview.totalKcal, 900);
      expect(updatedDayOverview.entryCount, 2);
      expect(updatedWeekOverview.totalConsumedKcal, 900);

      final deleted = await container
          .read(calorieEntriesControllerProvider.notifier)
          .deleteEntry('new-entry');

      expect(deleted, isTrue);

      final deletedDayOverview = await container.read(
        calorieWeekDayOverviewForDateProvider(mutatedDay).future,
      );
      final deletedWeekOverview = await container.read(
        calorieWeekOverviewProvider.future,
      );

      expect(deletedDayOverview.totalKcal, 400);
      expect(deletedDayOverview.entryCount, 1);
      expect(deletedWeekOverview.totalConsumedKcal, 400);
    },
  );

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
    expect(overview.carryoverBeforeTodayKcal, -50);
    expect(overview.todayFlexibleGoalKcal, 1750);
  });

  test(
    'calorieWeekOverview resets previous-run carryover',
    () async {
      final today = DateTime(2026, 4, 10);
      final cycleStartDay = today.subtract(const Duration(days: 9));
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
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(today);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(calorieWeekOverviewProvider.future);

      expect(overview.balanceStartDate, cycleStartDay);
      expect(overview.carryoverBeforeTodayKcal, 0);
      expect(overview.todayFlexibleGoalKcal, 2000);
      expect(overview.totalConsumedKcal, 4000);
      expect(overview.totalGoalKcal, 6000);
      expect(overview.remainingKcal, 2000);
    },
  );

  test(
    'calorieWeekOverview ignores empty days before first food log',
    () async {
      final today = DateTime(2026, 4, 8);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'first-tracked-day',
            loggedAt: today.add(const Duration(hours: 9)),
            totalKcal: 1200,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2300,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 2),
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
        ],
      );
      addTearDown(container.dispose);

      final provider = calorieWeekOverviewForWindowProvider(today);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      final overview = await container.read(provider.future);

      expect(overview.days.last.date, today);
      expect(
        overview.days.first.date,
        today.subtract(const Duration(days: 6)),
      );

      expect(overview.balanceStartDate, today);
      expect(overview.carryoverBeforeTodayKcal, 0);
      expect(overview.todayFlexibleGoalKcal, 2300);
    },
  );

  test(
    'calorieWeekOverview keeps the same balance cycle through weekly check-ins',
    () async {
      final today = DateTime(2026, 4, 10);
      final yesterday = today.subtract(const Duration(days: 1));
      final cycleStartDay = today.subtract(const Duration(days: 9));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'cycle-start-surplus',
            loggedAt: cycleStartDay.add(const Duration(hours: 12)),
            totalKcal: 2300,
          ),
          for (var offset = 1; offset <= 7; offset += 1)
            _entry(
              'balanced-before-checkin-$offset',
              loggedAt: cycleStartDay.add(
                Duration(days: offset, hours: 12),
              ),
              totalKcal: 2000,
            ),
          _entry(
            'weekly-checkin-day',
            loggedAt: yesterday.add(const Duration(hours: 12)),
            totalKcal: 1900,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: const CalorieGoalSettings.empty()
            .applyGoalChange(
              changedAt: DateTime(2026, 4),
              dailyKcalGoal: 2000,
              calculatorProfile: null,
            )
            .applyGoalChange(
              changedAt: DateTime(2026, 4, 9, 9),
              dailyKcalGoal: 1900,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
              weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                windowStartDate: DateTime(2026, 4, 2),
                windowEndDate: DateTime(2026, 4, 8),
                trendWeightChangePerDay: -0.05,
                calculatedTrueTdeeKcal: 2300,
                averageActiveKcal: 320,
                lowConfidence: false,
              ),
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
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(today);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(calorieWeekOverviewProvider.future);

      expect(overview.balanceStartDate, cycleStartDay);
      expect(overview.carryoverBeforeTodayKcal, 0);
      expect(overview.todayFlexibleGoalKcal, 1900);
    },
  );

  test(
    'calorieWeekOverview does not reload visible range when goal '
    'resolves later',
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
      var rangeReadCount = 0;
      var dayReadCount = 0;
      logRepository
        ..onReadEntriesInRange = (startInclusive, endExclusive) {
          rangeReadCount += 1;
          return _readLogEntriesInRange(
            logRepository,
            startInclusive: startInclusive,
            endExclusive: endExclusive,
          );
        }
        ..onReadEntriesForDay = (day) async {
          dayReadCount += 1;
          return _readLogEntriesForDay(logRepository, day);
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
      expect(initialOverview.totalGoalKcal, 2500);
      expect(rangeReadCount, 1);
      expect(dayReadCount, 0);

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
      expect(rangeReadCount, 1);
      expect(dayReadCount, 0);
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

  test(
    'calorieWeekOverview excludes practice food before counting start',
    () async {
      final practiceDay = DateTime(2026, 4, 23);
      final startDay = DateTime(2026, 4, 24);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'practice-food',
            loggedAt: practiceDay.add(const Duration(hours: 12)),
            totalKcal: 900,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: null,
          effectiveDate: startDay,
          countingStartDate: startDay,
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
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(startDay);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(
        calorieWeekOverviewProvider.future,
      );

      expect(overview.balanceStartDate, startDay);
      expect(overview.totalConsumedKcal, 0);
      expect(overview.totalGoalKcal, 1200);
      expect(overview.remainingKcal, 1200);
      expect(overview.carryoverBeforeTodayKcal, 0);
      expect(overview.todayFlexibleGoalKcal, 1200);
      expect(
        overview.days.firstWhere((day) => day.date == practiceDay).totalKcal,
        900,
      );
      expect(
        overview.days.firstWhere((day) => day.date == practiceDay).goalKcal,
        0,
      );
    },
  );

  test(
    'calorieWeekOverview shows negative carryover on final run day',
    () async {
      final startDay = DateTime(2026, 4, 24);
      final today = DateTime(2026, 4, 30);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'day-24',
            loggedAt: DateTime(2026, 4, 24, 12),
            totalKcal: 2370,
          ),
          _entry(
            'day-25',
            loggedAt: DateTime(2026, 4, 25, 12),
            totalKcal: 1806,
          ),
          _entry(
            'day-26',
            loggedAt: DateTime(2026, 4, 26, 12),
            totalKcal: 898,
          ),
          _entry(
            'day-27',
            loggedAt: DateTime(2026, 4, 27, 12),
            totalKcal: 1370,
          ),
          _entry(
            'day-28',
            loggedAt: DateTime(2026, 4, 28, 12),
            totalKcal: 1498,
          ),
          _entry(
            'day-29',
            loggedAt: DateTime(2026, 4, 29, 12),
            totalKcal: 1296,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 1200,
          calculatorProfile: null,
          effectiveDate: startDay,
          countingStartDate: startDay,
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
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(today);
      await container.read(calorieGoalControllerProvider.future);
      final overview = await container.read(calorieWeekOverviewProvider.future);

      expect(overview.totalConsumedKcal, 9238);
      expect(overview.totalGoalKcal, 8400);
      expect(overview.remainingKcal, -838);
      expect(overview.carryoverBeforeTodayKcal, -2038);
      expect(overview.todayFlexibleGoalKcal, -838);
    },
  );
}

class _DelayedCalorieSettingsRepository implements CalorieSettingsRepository {
  final _controller = StreamController<CalorieGoalSettings>.broadcast();

  CalorieGoalSettings _settings = const CalorieGoalSettings.empty();

  @override
  Stream<CalorieGoalSettings> watchSettings() async* {
    yield _settings;
    yield* _controller.stream;
  }

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
