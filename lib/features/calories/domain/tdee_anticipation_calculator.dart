import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';

/// Pure calculation helper for weight goal anticipation
/// and trend extrapolation.
abstract final class TdeeAnticipationCalculator {
  /// Minimum daily rate (5g/day) to consider a trend active.
  static const double minDailyRateKg = 0.005;

  /// Calculates anticipation projection based on weight trend and target.
  static TdeeAnticipationProjection? calculate({
    required double currentWeightKg,
    required double? targetWeightKg,
    required CalorieGoalMode? goalMode,
    required double recentWeightTrendKgPerDay,
    required DateTime startDate,
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
        projectedDate: startDate,
        isAchieved: true,
      );
    }

    final isMovingAway = isLosing
        ? recentWeightTrendKgPerDay >= -minDailyRateKg
        : recentWeightTrendKgPerDay <= minDailyRateKg;

    if (isMovingAway) {
      return const TdeeAnticipationProjection();
    }

    final remainingKg = (targetWeightKg - currentWeightKg).abs();
    final effectiveDailyRate = recentWeightTrendKgPerDay.abs();
    final rawDays = (remainingKg / effectiveDailyRate).round();
    final daysRemaining = rawDays.clamp(1, 365);
    final projectedDate = addDiaryDays(startDate, daysRemaining);

    return TdeeAnticipationProjection(projectedDate: projectedDate);
  }
}
