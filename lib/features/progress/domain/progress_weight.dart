import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_anticipation_calculator.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';

/// Number of days that the weight chart shows.
const int progressWeightDayCount = 28;

/// Weight trend of the last four weeks with the forecast for the goal.
@immutable
class ProgressWeight {
  /// Creates the weight progress.
  const new({
    required this.trend,
    required this.projectedGoalDate,
    required this.isGoalReached,
  });

  /// Adds the goal of [profile] and its forecast to [trend].
  factory fromTrend({
    required RecentWeightTrend trend,
    required CalorieCalculatorProfile? profile,
    required DateTime today,
  }) {
    final trendWeightKg = trend.trendWeightKg;
    final trendKgPerWeek = trend.trendKgPerWeek;
    final projection = trendWeightKg == null || trendKgPerWeek == null
        ? null
        : TdeeAnticipationCalculator.calculate(
            currentWeightKg: trendWeightKg,
            targetWeightKg: profile?.targetWeightKg,
            goalMode: profile?.goalMode,
            recentWeightTrendKgPerDay: trendKgPerWeek / DateTime.daysPerWeek,
            startDate: today,
          );
    return ProgressWeight(
      trend: trend,
      projectedGoalDate: projection == null || projection.isAchieved
          ? null
          : projection.projectedDate,
      isGoalReached: projection?.isAchieved ?? false,
    );
  }

  /// Weigh-ins and trend weight per day, oldest first.
  final RecentWeightTrend trend;

  /// Day on which the trend reaches the goal weight, or `null` when it does
  /// not move towards it or there is no goal weight.
  final DateTime? projectedGoalDate;

  /// Whether the trend weight already reached the goal weight.
  final bool isGoalReached;
}
