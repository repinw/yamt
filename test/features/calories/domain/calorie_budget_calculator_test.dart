import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';

void main() {
  test('resolves daily goal with one activity bonus and 1200 kcal floor', () {
    final result = CalorieBudgetCalculator.resolveDailyGoal(
      storedGoalKcal: 1100,
      activityDeltaKcal: 50,
    );

    expect(result.goalBeforeMinimumKcal, 1150);
    expect(result.goalKcal, minimumDailyCalorieBudgetKcal);
    expect(result.wasClampedToMinimum, isTrue);
  });

  test('calculates canonical carryover from finished day goals', () {
    final carryover = CalorieBudgetCalculator.calculateCarryover(
      const <CalorieCarryoverDay>[
        CalorieCarryoverDay(goalKcal: 2100, consumedKcal: 1900),
        CalorieCarryoverDay(goalKcal: 1800, consumedKcal: 2200),
      ],
    );

    expect(carryover, -200);
  });

  test('spreads carryover across remaining run days', () {
    final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
      carryoverKcal: -1200,
      remainingDays: 6,
    );

    expect(dailyAdjustment, -200);
  });

  test('classic toggles only affect today budget', () {
    final budget = CalorieBudgetCalculator.calculateClassicBudget(
      storedGoalKcal: 2000,
      activityDeltaKcal: 150,
      carryoverKcal: 300,
      consumedKcal: 1800,
      includeActivityDelta: false,
      includeCarryover: true,
    );

    expect(budget.goalKcal, 2300);
    expect(budget.includedActivityDeltaKcal, 0);
    expect(budget.includedCarryoverKcal, 300);
    expect(budget.remainingKcal, 500);
  });

  test('classic carryover can move budget below safety floor', () {
    final budget = CalorieBudgetCalculator.calculateClassicBudget(
      storedGoalKcal: 1400,
      activityDeltaKcal: 0,
      carryoverKcal: -1600,
      consumedKcal: 0,
      includeActivityDelta: true,
      includeCarryover: true,
    );

    expect(budget.goalKcal, 0);
    expect(budget.wasClampedToMinimum, isFalse);
  });

  test('full day budget includes activity and carryover', () {
    final budget = CalorieBudgetCalculator.calculateFullDayBudget(
      storedGoalKcal: 2000,
      activityDeltaKcal: 150,
      carryoverKcal: 300,
      consumedKcal: 1800,
    );

    expect(budget.goalKcal, 2450);
    expect(budget.includedActivityDeltaKcal, 150);
    expect(budget.includedCarryoverKcal, 300);
    expect(budget.remainingKcal, 650);
  });
}
