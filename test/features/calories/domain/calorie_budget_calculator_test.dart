import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';

void main() {
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

  test('distributes positive carryover without capping', () {
    final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
      carryoverKcal: 300,
      remainingDays: 3,
      baseGoalKcal: 2000,
    );

    expect(dailyAdjustment, 100);
  });

  test(
    'caps negative carryover at 350 kcal/day for high budget (Schutzregel C)',
    () {
      // 1200 kcal over budget / 2 days = 600 kcal/day raw reduction.
      // 20% of 2400 kcal = 480 kcal.
      // Capped at 350 kcal/day!
      final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -1200,
        remainingDays: 2,
        baseGoalKcal: 2400,
      );

      expect(dailyAdjustment, -350);
    },
  );

  test(
    'caps negative carryover at 20% of base budget when lower than 350 kcal',
    () {
      // 800 kcal over budget / 2 days = 400 kcal/day raw reduction.
      // Base budget 1400 kcal -> 20% is 280 kcal.
      // Capped at 280 kcal/day!
      final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -800,
        remainingDays: 2,
        baseGoalKcal: 1400,
      );

      expect(dailyAdjustment, -280);
    },
  );
}
