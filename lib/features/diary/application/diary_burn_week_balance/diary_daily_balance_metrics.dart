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
    required this.activitySegmentReferenceKcal,
    this.baseGoalKcal = 0,
    this.carryoverKcal = 0,
    this.todayActiveKcal = 0,
    this.expectedActivityKcal = 0,
    this.isActivityTrackingActive = false,
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

  /// Target basis used to size the activity segment visually.
  final double activitySegmentReferenceKcal;

  /// Stored base goal kcal before activity and carryover.
  final double baseGoalKcal;

  /// Carryover kcal adjustment distributed to today from previous days.
  final double carryoverKcal;

  /// Active energy tracked on this day.
  final int todayActiveKcal;

  /// Expected baseline active calories for this day.
  final double expectedActivityKcal;

  /// Whether activity tracking is active for this day.
  final bool isActivityTrackingActive;
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
  double? carryoverKcal,
  int todayActiveKcal = 0,
  double expectedActivityKcal = 0,
  bool isActivityTrackingActive = false,
}) {
  final realEatenKcal = totalKcal;
  final eatenKcal = math.max<double>(0, realEatenKcal + bufferAdjustmentKcal);
  final heartAdjustmentKcal = -heartCreditKcal;
  final targetKcal = resolveDiaryDailyTargetKcal(
    flexibleGoalKcal: flexibleGoalKcal,
    goalKcal: goalKcal,
    baseGoalKcal: baseGoalKcal,
    activitySegmentKcal: activitySegmentKcal,
  );
  final positiveActivitySegmentKcal = math.max<double>(0, activitySegmentKcal);
  final activitySegmentReferenceKcal = resolveDiaryActivitySegmentReferenceKcal(
    goalKcal: goalKcal,
    baseGoalKcal: baseGoalKcal,
    activitySegmentKcal: positiveActivitySegmentKcal,
  );
  final realDayLeftKcal = targetKcal - realEatenKcal;
  final dayLeftKcal = isHeartDay ? 0.0 : realDayLeftKcal + heartAdjustmentKcal;
  final resolvedCarryoverKcal = carryoverKcal ?? (flexibleGoalKcal - goalKcal);

  return DiaryDailyBalanceMetrics(
    bufferAdjustmentKcal: bufferAdjustmentKcal,
    realEatenKcal: realEatenKcal,
    eatenKcal: eatenKcal,
    realDayLeftKcal: realDayLeftKcal,
    heartAdjustmentKcal: heartAdjustmentKcal,
    dayLeftKcal: dayLeftKcal,
    targetKcal: targetKcal,
    activitySegmentKcal: positiveActivitySegmentKcal,
    activitySegmentReferenceKcal: activitySegmentReferenceKcal,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: resolvedCarryoverKcal,
    todayActiveKcal: todayActiveKcal,
    expectedActivityKcal: expectedActivityKcal,
    isActivityTrackingActive: isActivityTrackingActive,
  );
}

/// Resolves the daily target used by the diary daily balance card.
double resolveDiaryDailyTargetKcal({
  required double flexibleGoalKcal,
  required double goalKcal,
  required double baseGoalKcal,
  required double activitySegmentKcal,
}) {
  final alreadyCountedActivityKcal = math.max<double>(
    0,
    goalKcal - baseGoalKcal,
  );
  final positiveActivitySegmentKcal = math.max<double>(0, activitySegmentKcal);
  final missingActivityKcal = math.max<double>(
    0,
    positiveActivitySegmentKcal - alreadyCountedActivityKcal,
  );
  return flexibleGoalKcal + missingActivityKcal;
}

/// Resolves the visual target basis for the activity segment.
double resolveDiaryActivitySegmentReferenceKcal({
  required double goalKcal,
  required double baseGoalKcal,
  required double activitySegmentKcal,
}) {
  final positiveActivitySegmentKcal = math.max<double>(0, activitySegmentKcal);
  return math.max<double>(
    goalKcal,
    baseGoalKcal + positiveActivitySegmentKcal,
  );
}
