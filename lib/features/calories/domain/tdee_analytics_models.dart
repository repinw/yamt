import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

/// One day of analytics data combining TDEE, intake, and weight.
class TdeeAnalyticsPoint {
  /// Creates one daily analytics point.
  const TdeeAnalyticsPoint({
    required this.day,
    this.learnedBaseTdeeKcal,
    this.totalTdeeKcal,
    this.targetKcal,
    this.intakeKcal,
    this.scaleWeightKg,
    this.trendWeightKg,
    this.isHolding = false,
  });

  /// Calendar day.
  final DateTime day;

  /// Learned Base-TDEE (without activity credit).
  final double? learnedBaseTdeeKcal;

  /// Total TDEE (Base-TDEE + activity credit) for flux range upper bound.
  final double? totalTdeeKcal;

  /// Daily calorie target.
  final double? targetKcal;

  /// Actual logged intake.
  final double? intakeKcal;

  /// Measured scale weight.
  final double? scaleWeightKg;

  /// Smoothed trend weight.
  final double? trendWeightKg;

  /// Whether data was held/interpolated due to missing logs.
  final bool isHolding;
}

/// Single point along a projected future trendline.
class TdeeProjectionPoint {
  /// Creates a projection point.
  const TdeeProjectionPoint({
    required this.day,
    required this.weightKg,
  });

  /// Calendar day.
  final DateTime day;

  /// Projected weight in kg.
  final double weightKg;
}

/// Projection details for reaching target weight.
class TdeeAnticipationProjection {
  /// Creates an anticipation projection.
  const TdeeAnticipationProjection({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.trendSpeedKgPerWeek,
    required this.projectionPoints,
    this.plannedSpeedKgPerWeek,
    this.projectedDate,
    this.daysRemaining,
    this.isAchieved = false,
    this.isMovingAway = false,
  });

  /// Current starting weight for projection.
  final double currentWeightKg;

  /// Desired goal weight.
  final double targetWeightKg;

  /// Observed recent rate of weight change (kg/week, negative = losing).
  final double trendSpeedKgPerWeek;

  /// User-defined planned rate of change from profile.
  final double? plannedSpeedKgPerWeek;

  /// Projected date when target weight will be met.
  final DateTime? projectedDate;

  /// Days remaining until goal.
  final int? daysRemaining;

  /// Whether target weight is already reached or surpassed.
  final bool isAchieved;

  /// Whether trend is moving in the wrong direction.
  final bool isMovingAway;

  /// Future points forming the dashed projection curve.
  final List<TdeeProjectionPoint> projectionPoints;
}

/// Summary metrics shown in the header and insights card.
class TdeeAnalyticsSummary {
  /// Creates analytics summary.
  const TdeeAnalyticsSummary({
    required this.averageTdeeKcal,
    required this.tdeeDifferenceKcal,
    this.threeDayDeltaKcal,
    this.sevenDayDeltaKcal,
    this.fourteenDayDeltaKcal,
    this.averageIntakeKcal,
    this.currentWeightKg,
    this.weightChangeKg,
  });

  /// Average TDEE across the selected period.
  final double averageTdeeKcal;

  /// Difference from start to end of selected period.
  final double tdeeDifferenceKcal;

  /// Delta in TDEE over the last 3 days.
  final double? threeDayDeltaKcal;

  /// Delta in TDEE over the last 7 days.
  final double? sevenDayDeltaKcal;

  /// Delta in TDEE over the last 14 days.
  final double? fourteenDayDeltaKcal;

  /// Average logged intake over the period.
  final double? averageIntakeKcal;

  /// Latest weight in the period.
  final double? currentWeightKg;

  /// Total weight change from start to end of period.
  final double? weightChangeKg;
}

/// State object combining all analytics data for the view.
class TdeeAnalyticsState {
  /// Creates the analytics state.
  const TdeeAnalyticsState({
    required this.selectedCycle,
    required this.availableCycles,
    required this.timeRange,
    required this.points,
    required this.summary,
    this.anticipation,
    this.showAnticipation = true,
  });

  /// Currently selected cycle.
  final TdeeAnalyticsGoalCycle selectedCycle;

  /// All available cycles for picker.
  final List<TdeeAnalyticsGoalCycle> availableCycles;

  /// Currently active time filter.
  final TdeeAnalyticsTimeRange timeRange;

  /// Daily points in chronological order.
  final List<TdeeAnalyticsPoint> points;

  /// Aggregated summary numbers.
  final TdeeAnalyticsSummary summary;

  /// Optional goal anticipation projection.
  final TdeeAnticipationProjection? anticipation;

  /// Whether anticipation lines/insights are visible.
  final bool showAnticipation;
}
