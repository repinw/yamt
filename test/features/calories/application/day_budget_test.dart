import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/day_budget.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';

final _today = DateTime(2026, 10, 8);

/// Carbs follow the goal with the carryover, protein the goal alone, fat a
/// tenth of the carryover, so each part of the result can be told apart.
class _Nutrition implements DailyNutritionTargetResolver {
  @override
  DailyNutritionTarget resolveTarget({
    required DateTime day,
    required double goalKcal,
    double carryoverKcal = 0.0,
  }) => DailyNutritionTarget(
    date: day,
    goalKcal: goalKcal + carryoverKcal,
    carbsGrams: (goalKcal + carryoverKcal) / 10,
    proteinGrams: goalKcal / 20,
    fatGrams: carryoverKcal / 10,
  );

  @override
  DailyNutritionTarget resolveBaseTarget({
    required DateTime day,
    required double goalKcal,
  }) => resolveTarget(day: day, goalKcal: goalKcal);
}

CalorieWeekOverview _week({
  required DateTime day,
  double goalKcal = 2000,
  double carryoverKcal = 300,
  bool isPreviousDayClosed = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
}) => CalorieWeekOverview(
  days: [
    CalorieWeekDayOverview(
      date: day,
      totalKcal: 0,
      goalKcal: goalKcal,
      entryCount: 0,
    ),
  ],
  totalConsumedKcal: 0,
  totalGoalKcal: goalKcal,
  remainingKcal: goalKcal,
  balanceStartDate: day,
  carryoverBeforeTodayKcal: carryoverKcal,
  todayFlexibleGoalKcal: goalKcal + carryoverKcal,
  goalStartsInFuture: nextGoalStartDate != null,
  nextGoalStartDate: nextGoalStartDate,
  futureGoalKcal: futureGoalKcal,
  isPreviousDayClosed: isPreviousDayClosed,
);

DayBudget _budget(CalorieWeekOverview week) =>
    resolveDayBudget(week: week, today: _today, nutrition: _Nutrition());

void main() {
  final yesterday = _today.subtract(const Duration(days: 1));
  final tomorrow = _today.add(const Duration(days: 1));

  final rules =
      <
        ({
          String name,
          CalorieWeekOverview week,
          double goalKcal,
          double carryoverKcal,
        })
      >[
        (
          name: 'a past day gets no carryover',
          week: _week(day: yesterday),
          goalKcal: 2000,
          carryoverKcal: 0,
        ),
        (
          name: 'today gets its carryover',
          week: _week(day: _today),
          goalKcal: 2000,
          carryoverKcal: 300,
        ),
        (
          name: 'a planned day counts its plans',
          week: _week(day: tomorrow, carryoverKcal: 0),
          goalKcal: 2000,
          carryoverKcal: 0,
        ),
        (
          name: 'tomorrow after a closed day gets the carryover',
          week: _week(day: tomorrow, isPreviousDayClosed: true),
          goalKcal: 2000,
          carryoverKcal: 300,
        ),
        (
          name: 'a practice day borrows the later goal',
          week: _week(
            day: _today,
            goalKcal: 0,
            carryoverKcal: 0,
            nextGoalStartDate: tomorrow,
            futureGoalKcal: 1800,
          ),
          goalKcal: 1800,
          carryoverKcal: 0,
        ),
      ];

  for (final rule in rules) {
    test(rule.name, () {
      final budget = _budget(rule.week);

      expect(budget.goalKcal, rule.goalKcal);
      expect(
        budget.target.carbsGrams,
        (rule.goalKcal + rule.carryoverKcal) / 10,
      );
    });
  }

  test('the carryover macro delta is the target with minus without the '
      'carryover', () {
    final budget = _budget(_week(day: _today));

    expect(budget.carryoverMacroDelta, (carbs: 30.0, protein: 0.0, fat: 30.0));
  });

  test('a day on or after the later goal start is no practice day', () {
    final week = _week(
      day: tomorrow,
      nextGoalStartDate: tomorrow,
      futureGoalKcal: 1800,
    );

    expect(isPracticeDay(week: week, day: tomorrow), isFalse);
    expect(dayGoalKcal(week), 2000);
  });
}
