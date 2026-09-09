import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';

/// Pure calculation helper for weight goal anticipation
/// and trend extrapolation.
abstract final class TdeeAnticipationCalculator {
  /// Maximum days into the future for chart projections.
  static const int maxProjectionDays = 180;

  /// Minimum daily rate (5g/day) to consider a trend active.
  static const double minDailyRateKg = 0.005;

  /// Calculates anticipation projection based on weight trend and target.
  static TdeeAnticipationProjection? calculate({
    required double currentWeightKg,
    required double? targetWeightKg,
    required CalorieGoalMode? goalMode,
    required double recentWeightTrendKgPerDay,
    required DateTime startDate,
    double? plannedSpeedKgPerWeek,
  }) {
    if (targetWeightKg == null || goalMode == null) {
      return null;
    }
    if (goalMode == CalorieGoalMode.maintain) {
      return null;
    }

    final isLosing = goalMode == CalorieGoalMode.lose;
    final isAchieved = isLosing
        ? currentWeightKg <= targetWeightKg
        : currentWeightKg >= targetWeightKg;

    if (isAchieved) {
      return TdeeAnticipationProjection(
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        trendSpeedKgPerWeek: recentWeightTrendKgPerDay * 7,
        plannedSpeedKgPerWeek: plannedSpeedKgPerWeek,
        projectedDate: startDate,
        daysRemaining: 0,
        isAchieved: true,
        projectionPoints: const <TdeeProjectionPoint>[],
      );
    }

    final isMovingAway = isLosing
        ? recentWeightTrendKgPerDay >= -minDailyRateKg
        : recentWeightTrendKgPerDay <= minDailyRateKg;

    if (isMovingAway) {
      return TdeeAnticipationProjection(
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        trendSpeedKgPerWeek: recentWeightTrendKgPerDay * 7,
        plannedSpeedKgPerWeek: plannedSpeedKgPerWeek,
        isMovingAway: true,
        projectionPoints: const <TdeeProjectionPoint>[],
      );
    }

    final remainingKg = (targetWeightKg - currentWeightKg).abs();
    final effectiveDailyRate = recentWeightTrendKgPerDay.abs();
    final rawDays = (remainingKg / effectiveDailyRate).round();
    final daysRemaining = rawDays.clamp(1, 365);
    final projectedDate = startDate.add(Duration(days: daysRemaining));

    final projectionPoints = _buildProjectionPoints(
      startDate: startDate,
      startWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      dailyRate: recentWeightTrendKgPerDay,
      daysRemaining: daysRemaining,
    );

    return TdeeAnticipationProjection(
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      trendSpeedKgPerWeek: recentWeightTrendKgPerDay * 7,
      plannedSpeedKgPerWeek: plannedSpeedKgPerWeek,
      projectedDate: projectedDate,
      daysRemaining: daysRemaining,
      projectionPoints: projectionPoints,
    );
  }

  static List<TdeeProjectionPoint> _buildProjectionPoints({
    required DateTime startDate,
    required double startWeightKg,
    required double targetWeightKg,
    required double dailyRate,
    required int daysRemaining,
  }) {
    final points = <TdeeProjectionPoint>[
      TdeeProjectionPoint(day: startDate, weightKg: startWeightKg),
    ];
    final cappedDays = daysRemaining.clamp(1, maxProjectionDays);
    final stepDays = (cappedDays / 10).ceil().clamp(1, 7);

    for (var d = stepDays; d < cappedDays; d += stepDays) {
      points.add(
        TdeeProjectionPoint(
          day: startDate.add(Duration(days: d)),
          weightKg: startWeightKg + (dailyRate * d),
        ),
      );
    }

    if (daysRemaining <= maxProjectionDays) {
      points.add(
        TdeeProjectionPoint(
          day: startDate.add(Duration(days: daysRemaining)),
          weightKg: targetWeightKg,
        ),
      );
    }

    return List<TdeeProjectionPoint>.unmodifiable(points);
  }
}
