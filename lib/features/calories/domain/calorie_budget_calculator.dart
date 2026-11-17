import 'dart:math' as math;

/// Minimum kcal used by every calorie budget calculation.
const minimumDailyCalorieBudgetKcal = 1200.0;

/// One finished day used for carryover math.
class CalorieCarryoverDay {
  /// Creates a carryover day.
  const new({required this.goalKcal, required this.consumedKcal});

  /// The canonical goal for this day.
  final double goalKcal;

  /// Logged kcal for this day.
  final double consumedKcal;
}

/// Largest share of a day's goal that the carryover may add or take away.
const maxCarryoverGoalShare = 0.2;

/// Largest carryover of one day in kcal, in both directions.
const maxCarryoverKcal = 350.0;

/// Shared calorie carryover math.
abstract final class CalorieBudgetCalculator {
  /// The most kcal the carryover may add to or take from a day with
  /// [goalKcal]: [maxCarryoverGoalShare] of the goal, at most
  /// [maxCarryoverKcal].
  static double carryoverLimitKcal(double goalKcal) =>
      math.min(goalKcal * maxCarryoverGoalShare, maxCarryoverKcal);

  /// Spreads the [carryoverKcal] balance of the finished days over the
  /// [remainingDays] of the run, the day itself included, and returns the
  /// carryover of the day with [baseGoalKcal], in whole kcal.
  ///
  /// The carryover is limited by [carryoverLimitKcal] in both directions
  /// (Schutzregel C), and a negative one never takes the budget below
  /// [minimumDailyCalorieBudgetKcal].
  static double distributeCarryover({
    required double carryoverKcal,
    required int remainingDays,
    required double baseGoalKcal,
  }) {
    final limit = carryoverLimitKcal(baseGoalKcal);
    final daily = (carryoverKcal / math.max(1, remainingDays)).clamp(
      -limit,
      limit,
    );
    final floor = math.min(0, minimumDailyCalorieBudgetKcal - baseGoalKcal);
    return (daily < 0 ? math.max(daily, floor) : daily).roundToDouble();
  }
}
