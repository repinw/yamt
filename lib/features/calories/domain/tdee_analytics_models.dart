/// One day of analytics data combining TDEE and weight.
class TdeeAnalyticsPoint {
  /// Creates one daily analytics point.
  const new({
    required this.day,
    this.learnedBaseTdeeKcal,
    this.totalTdeeKcal,
    this.scaleWeightKg,
    this.trendWeightKg,
    this.isHolding = false,
  });

  /// Calendar day.
  final DateTime day;

  /// The daily TDEE estimate.
  final double? learnedBaseTdeeKcal;

  /// The TDEE that this day's smoothed intake and weight trend imply,
  /// before the ramp-up and the daily cap.
  final double? totalTdeeKcal;

  /// Measured scale weight, when the user weighed in on this day.
  final double? scaleWeightKg;

  /// Estimated real weight: interpolated and smoothed scale weights.
  final double? trendWeightKg;

  /// Whether too few logged days held the estimate.
  final bool isHolding;
}

/// When a weight goal is reached at the current trend.
class TdeeAnticipationProjection {
  /// Creates an anticipation projection.
  const new({this.projectedDate, this.isAchieved = false});

  /// Projected date when target weight will be met, or `null` when the
  /// trend moves away from it.
  final DateTime? projectedDate;

  /// Whether target weight is already reached or surpassed.
  final bool isAchieved;
}

/// State object combining all analytics data for the view.
class TdeeAnalyticsState {
  /// Creates the analytics state.
  const new({required this.points});

  /// Daily points in chronological order.
  final List<TdeeAnalyticsPoint> points;
}
