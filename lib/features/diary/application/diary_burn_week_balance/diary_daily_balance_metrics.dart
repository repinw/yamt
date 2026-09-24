import 'dart:math' as math;

/// Derived values for the selected day's balance summary and progress bar.
class DiaryDailyBalanceMetrics {
  /// Creates derived daily balance metrics.
  const new({
    required this.bufferAdjustmentKcal,
    required this.realEatenKcal,
    required this.eatenKcal,
    required this.realDayLeftKcal,
    required this.dayLeftKcal,
    required this.targetKcal,
    this.baseGoalKcal = 0,
    this.carryoverKcal = 0,
  });

  /// Calorie adjustment from buffer.
  final double bufferAdjustmentKcal;

  /// Real logged kcal before adjustments.
  final double realEatenKcal;

  /// Displayed eaten calories after buffer adjustment.
  final double eatenKcal;

  /// Real selected-day calories left.
  final double realDayLeftKcal;

  /// Displayed calories left.
  final double dayLeftKcal;

  /// Final daily target shown by the daily progress bar.
  final double targetKcal;

  /// Stored base goal kcal before carryover.
  final double baseGoalKcal;

  /// Carryover kcal adjustment distributed to today from previous days.
  final double carryoverKcal;
}

/// Resolves daily target and display values from scalar inputs.
DiaryDailyBalanceMetrics resolveDiaryDailyBalanceMetrics({
  required double flexibleGoalKcal,
  required double totalKcal,
  required double goalKcal,
  required double baseGoalKcal,
  double bufferAdjustmentKcal = 0,
  double? carryoverKcal,
}) {
  final realEatenKcal = totalKcal;
  final eatenKcal = math.max<double>(0, realEatenKcal + bufferAdjustmentKcal);
  final realDayLeftKcal = flexibleGoalKcal - realEatenKcal;
  final dayLeftKcal = flexibleGoalKcal - eatenKcal;
  final resolvedCarryoverKcal = carryoverKcal ?? (flexibleGoalKcal - goalKcal);

  return DiaryDailyBalanceMetrics(
    bufferAdjustmentKcal: bufferAdjustmentKcal,
    realEatenKcal: realEatenKcal,
    eatenKcal: eatenKcal,
    realDayLeftKcal: realDayLeftKcal,
    dayLeftKcal: dayLeftKcal,
    targetKcal: flexibleGoalKcal,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: resolvedCarryoverKcal,
  );
}
