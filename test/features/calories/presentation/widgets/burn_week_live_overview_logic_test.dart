import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

void main() {
  test('live week start ignores a stored future anchor', () {
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: DateTime(2026, 4, 21, 12),
      balanceStartDate: DateTime(2026, 4, 21),
      storedWeekStartDayKey: '2026-4-22',
    );

    expect(currentWeekStartDate, DateTime(2026, 4, 21));
  });

  test('live week start ignores a stored anchor before the active cycle', () {
    final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
      currentDay: DateTime(2026, 4, 21, 12),
      balanceStartDate: DateTime(2026, 4, 21),
      storedWeekStartDayKey: '2026-4-14',
    );

    expect(currentWeekStartDate, DateTime(2026, 4, 21));
  });

  test('run week one ignores previous overflow completely', () {
    final previousOverflowKcal = resolveBurnWeekPreviousOverflowKcal(
      cycleCarryoverBeforeTodayKcal: 250,
      currentWeekCarryoverBeforeTodayKcal: 50,
      runWeekNumber: 1,
    );

    expect(previousOverflowKcal, 0);
  });

  test(
    'current Burn Week carryover uses base goals without activity bonus',
    () {
      final carryover = resolveBurnWeekCarryoverBeforeTodayKcal(
        weekOverview: CalorieWeekOverview(
          days: <CalorieWeekDayOverview>[
            CalorieWeekDayOverview(
              date: DateTime(2026, 4, 20),
              totalKcal: 1500,
              goalKcal: 2350,
              baseGoalKcal: 2000,
              entryCount: 1,
            ),
            CalorieWeekDayOverview(
              date: DateTime(2026, 4, 21),
              totalKcal: 0,
              goalKcal: 2000,
              entryCount: 0,
            ),
          ],
          totalConsumedKcal: 1500,
          totalGoalKcal: 4350,
          remainingKcal: 2850,
          balanceStartDate: DateTime(2026, 4, 20),
          carryoverBeforeTodayKcal: 500,
          todayFlexibleGoalKcal: 2500,
          goalStartsInFuture: false,
          nextGoalStartDate: null,
          futureGoalKcal: null,
        ),
        currentWeekStartDate: DateTime(2026, 4, 20),
        today: DateTime(2026, 4, 21),
      );

      expect(carryover, 500);
    },
  );

  test('live metrics ignore pre-start goal spikes from older visible days', () {
    final today = DateTime(2026, 4, 21, 12);
    final metrics = resolveBurnWeekLiveMetrics(
      now: today,
      weekOverview: CalorieWeekOverview(
        days: <CalorieWeekDayOverview>[
          for (var day = 15; day <= 20; day += 1)
            CalorieWeekDayOverview(
              date: DateTime(2026, 4, day),
              totalKcal: 0,
              goalKcal: 4000,
              entryCount: 0,
            ),
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 21),
            totalKcal: 600,
            goalKcal: 2000,
            entryCount: 1,
          ),
        ],
        totalConsumedKcal: 600,
        totalGoalKcal: 26000,
        remainingKcal: 25400,
        balanceStartDate: DateTime(2026, 4, 15),
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      ),
      todayOverview: CalorieWeekDayOverview(
        date: DateTime(2026, 4, 21),
        totalKcal: 600,
        goalKcal: 2000,
        entryCount: 1,
      ),
      currentWeekStartDate: DateTime(2026, 4, 21),
      previousWeekOverflowKcal: 0,
      heartCreditKcal: 0,
      plannedLaterTodayKcal: 0,
      safeZoneMultiplier: 1,
    );

    expect(metrics.dailyGoalKcal, 2000);
    expect(metrics.weeklyGoalKcal, 14000);
    expect(metrics.consumedKcal, 600);
    expect(metrics.targetKcal, closeTo(1000, 0.001));
  });

  test('planned later today stays out of actual consumed kcal', () {
    final now = DateTime(2026, 4, 21, 12);
    final plannedLaterTodayKcal = resolveBurnWeekPlannedLaterTodayKcal(
      todayEntries: <CalorieEntry>[
        CalorieEntry.create(
          id: 'now',
          userId: 'user-1',
          name: 'Now',
          mealType: MealType.breakfast,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 600,
          per100Protein: 10,
          per100Carbs: 10,
          per100Fat: 10,
          loggedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        CalorieEntry.create(
          id: 'later',
          userId: 'user-1',
          name: 'Later',
          mealType: MealType.lunch,
          consumedAmount: 100,
          consumedUnit: ConsumedUnit.grams,
          per100Kcal: 500,
          per100Protein: 10,
          per100Carbs: 10,
          per100Fat: 10,
          loggedAt: DateTime(2026, 4, 21, 18),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      now: now,
    );
    final metrics = resolveBurnWeekLiveMetrics(
      now: now,
      weekOverview: CalorieWeekOverview(
        days: <CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 21),
            totalKcal: 1100,
            goalKcal: 2000,
            entryCount: 2,
          ),
        ],
        totalConsumedKcal: 1100,
        totalGoalKcal: 2000,
        remainingKcal: 900,
        balanceStartDate: DateTime(2026, 4, 21),
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      ),
      todayOverview: CalorieWeekDayOverview(
        date: DateTime(2026, 4, 21),
        totalKcal: 1100,
        goalKcal: 2000,
        entryCount: 2,
      ),
      currentWeekStartDate: DateTime(2026, 4, 21),
      previousWeekOverflowKcal: 0,
      heartCreditKcal: 0,
      plannedLaterTodayKcal: plannedLaterTodayKcal,
      safeZoneMultiplier: 1,
    );

    expect(plannedLaterTodayKcal, 500);
    expect(metrics.consumedKcal, 600);
    expect(metrics.plannedLaterKcal, 500);
  });

  test('current heart day counts as a complete perfect day', () {
    final now = DateTime(2026, 4, 21, 12);
    final metrics = resolveBurnWeekLiveMetrics(
      now: now,
      weekOverview: CalorieWeekOverview(
        days: <CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 21),
            totalKcal: 5000,
            goalKcal: 2000,
            entryCount: 3,
            isHeartDay: true,
          ),
        ],
        totalConsumedKcal: 2000,
        totalGoalKcal: 2000,
        remainingKcal: 0,
        balanceStartDate: DateTime(2026, 4, 21),
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      ),
      todayOverview: CalorieWeekDayOverview(
        date: DateTime(2026, 4, 21),
        totalKcal: 5000,
        goalKcal: 2000,
        entryCount: 3,
        isHeartDay: true,
      ),
      currentWeekStartDate: DateTime(2026, 4, 21),
      previousWeekOverflowKcal: 0,
      heartCreditKcal: 0,
      plannedLaterTodayKcal: 0,
      safeZoneMultiplier: 1,
    );

    expect(metrics.actualConsumedKcal, 2000);
    expect(metrics.consumedKcal, 2000);
    expect(metrics.targetKcal, 2000);
  });

  test('heart credit moves the flame and keeps real food separate', () {
    final now = DateTime(2026, 4, 21, 23, 59);
    final metrics = resolveBurnWeekLiveMetrics(
      now: now,
      weekOverview: CalorieWeekOverview(
        days: <CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 21),
            totalKcal: 600,
            goalKcal: 2000,
            entryCount: 1,
          ),
        ],
        totalConsumedKcal: 600,
        totalGoalKcal: 2000,
        remainingKcal: 1400,
        balanceStartDate: DateTime(2026, 4, 21),
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      ),
      todayOverview: CalorieWeekDayOverview(
        date: DateTime(2026, 4, 21),
        totalKcal: 600,
        goalKcal: 2000,
        entryCount: 1,
      ),
      currentWeekStartDate: DateTime(2026, 4, 21),
      previousWeekOverflowKcal: 0,
      heartCreditKcal: 2000,
      plannedLaterTodayKcal: 0,
      safeZoneMultiplier: 1,
    );

    expect(metrics.actualConsumedKcal, 600);
    expect(metrics.consumedKcal, 2600);
    expect(metrics.consumedRatio, closeTo(2600 / 14000, 0.001));
    expect(metrics.effectiveConsumedRatio, closeTo(2600 / 14000, 0.001));
  });

  test('current day progress stays bounded on DST transition dates', () {
    final springForwardProgress = resolveBurnWeekCurrentDayProgress(
      DateTime(2026, 3, 29, 23, 30),
    );
    final fallBackProgress = resolveBurnWeekCurrentDayProgress(
      DateTime(2026, 10, 25, 23, 30),
    );

    expect(springForwardProgress, inInclusiveRange(0.0, 1.0));
    expect(fallBackProgress, inInclusiveRange(0.0, 1.0));
    expect(springForwardProgress, greaterThan(0.9));
    expect(fallBackProgress, greaterThan(0.9));
  });
}
