import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';

void main() {
  test('spreads carryover across remaining run days', () {
    final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
      carryoverKcal: -1200,
      remainingDays: 6,
      baseGoalKcal: 2200,
    );

    expect(dailyAdjustment, -200);
  });

  test('distributes positive carryover below the limit as it is', () {
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
      // Base budget 1600 kcal -> 20% is 320 kcal, and 1280 stays above 1200.
      final dailyAdjustment = CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -800,
        remainingDays: 2,
        baseGoalKcal: 1600,
      );

      expect(dailyAdjustment, -320);
    },
  );

  test('K11: a negative carryover never takes the budget below 1,200', () {
    // 20% of 1400 would be −280, but 1400 − 280 is under 1200.
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -800,
        remainingDays: 2,
        baseGoalKcal: 1400,
      ),
      -200,
    );
    // K11 rows: 1.500 / −3.000 / day 2 → −300; 1.300 / −1.300 / day 7 →
    // −100; 1.200 / −2.000 / day 5 → 0.
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -3000,
        remainingDays: 6,
        baseGoalKcal: 1500,
      ),
      -300,
    );
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -1300,
        remainingDays: 1,
        baseGoalKcal: 1300,
      ),
      -100,
    );
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: -2000,
        remainingDays: 3,
        baseGoalKcal: 1200,
      ),
      0,
    );
  });

  test('K11: a positive carryover is capped like a negative one', () {
    // six days of 1.900 at 2.200 → +1.800 on day 7: +350.
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: 1800,
        remainingDays: 1,
        baseGoalKcal: 2200,
      ),
      350,
    );
    // 1.500, +1.200 on day 7: 20 % → +300.
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: 1200,
        remainingDays: 1,
        baseGoalKcal: 1500,
      ),
      300,
    );
    // 1.200, +600 on day 6: 20 % → +240.
    expect(
      CalorieBudgetCalculator.distributeCarryover(
        carryoverKcal: 600,
        remainingDays: 2,
        baseGoalKcal: 1200,
      ),
      240,
    );
  });

  test('K35: the limit is 20 % of the goal, at most 350 kcal', () {
    const rows = [
      (2200.0, 350.0),
      (1750.0, 350.0),
      (1600.0, 320.0),
      (1500.0, 300.0),
    ];
    for (final (goal, limit) in rows) {
      expect(
        CalorieBudgetCalculator.carryoverLimitKcal(goal),
        limit,
        reason: '$goal',
      );
    }
    expect(
      CalorieBudgetCalculator.carryoverLimitKcal(1200),
      closeTo(240, 1e-9),
    );
  });
}
