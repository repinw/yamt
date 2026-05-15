import 'dart:math' as math;

/// Derived values for the selected day's balance summary and progress bar.
class DiaryDailyBalanceMetrics {
  /// Creates derived daily balance metrics.
  const DiaryDailyBalanceMetrics({
    required this.bufferAdjustmentKcal,
    required this.realEatenKcal,
    required this.eatenKcal,
    required this.realDayLeftKcal,
    required this.heartAdjustmentKcal,
    required this.dayLeftKcal,
    required this.targetKcal,
    required this.activitySegmentKcal,
  });

  /// Calorie adjustment from active heart credit.
  final double bufferAdjustmentKcal;

  /// Real logged kcal before virtual heart credit is applied.
  final double realEatenKcal;

  /// Displayed eaten calories after buffer adjustment.
  final double eatenKcal;

  /// Real selected-day calories left before heart adjustment.
  final double realDayLeftKcal;

  /// Displayed heart adjustment for calories left.
  final double heartAdjustmentKcal;

  /// Displayed calories left after heart adjustment.
  final double dayLeftKcal;

  /// Final daily target shown by the daily progress bar.
  final double targetKcal;

  /// Positive activity kcal that extends the daily progress bar.
  final double activitySegmentKcal;
}

/// Resolves daily target and heart-adjusted display values from scalar inputs.
DiaryDailyBalanceMetrics resolveDiaryDailyBalanceMetrics({
  required double flexibleGoalKcal,
  required double totalKcal,
  required double goalKcal,
  required double baseGoalKcal,
  required double activitySegmentKcal,
  required double bufferAdjustmentKcal,
  required double heartCreditKcal,
  required bool isHeartDay,
}) {
  final realEatenKcal = totalKcal;
  final eatenKcal = math.max<double>(0, realEatenKcal + bufferAdjustmentKcal);
  final heartAdjustmentKcal = -heartCreditKcal;
  final alreadyCountedActivityKcal = math.max<double>(
    0,
    goalKcal - baseGoalKcal,
  );
  final positiveActivitySegmentKcal = math.max<double>(0, activitySegmentKcal);
  final missingActivityKcal = math.max<double>(
    0,
    positiveActivitySegmentKcal - alreadyCountedActivityKcal,
  );
  final targetKcal = flexibleGoalKcal + missingActivityKcal;
  final realDayLeftKcal = targetKcal - realEatenKcal;
  final dayLeftKcal = isHeartDay ? 0.0 : realDayLeftKcal + heartAdjustmentKcal;

  return DiaryDailyBalanceMetrics(
    bufferAdjustmentKcal: bufferAdjustmentKcal,
    realEatenKcal: realEatenKcal,
    eatenKcal: eatenKcal,
    realDayLeftKcal: realDayLeftKcal,
    heartAdjustmentKcal: heartAdjustmentKcal,
    dayLeftKcal: dayLeftKcal,
    targetKcal: targetKcal,
    activitySegmentKcal: positiveActivitySegmentKcal,
  );
}
