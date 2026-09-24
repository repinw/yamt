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

/// Shared calorie carryover math.
abstract final class CalorieBudgetCalculator {
  /// Calculate canonical carryover from finished days.
  static double calculateCarryover(Iterable<CalorieCarryoverDay> days) {
    return days.fold<double>(
      0,
      (sum, day) => sum + day.goalKcal - day.consumedKcal,
    );
  }

  /// Spread carryover across remaining days in the active goal run.
  ///
  /// For negative carryover (overeating), Schutzregel C caps the daily
  /// reduction to at most [maxReductionFraction] (default 20%) of
  /// [baseGoalKcal] or [maxReductionCapKcal] (default 350 kcal/day)
  /// to prevent the binge-restrict cycle.
  static double distributeCarryover({
    required double carryoverKcal,
    required int remainingDays,
    double? baseGoalKcal,
    double maxReductionFraction = 0.20,
    double maxReductionCapKcal = 350.0,
  }) {
    final resolvedRemainingDays = math.max(1, remainingDays);
    final rawDailyAdjustment = carryoverKcal / resolvedRemainingDays;
    if (rawDailyAdjustment >= 0) {
      return rawDailyAdjustment;
    }

    final rawReduction = rawDailyAdjustment.abs();
    final cap = baseGoalKcal != null && baseGoalKcal > 0
        ? math.min(baseGoalKcal * maxReductionFraction, maxReductionCapKcal)
        : maxReductionCapKcal;
    final effectiveReduction = math.min(rawReduction, cap);
    return -effectiveReduction;
  }
}
