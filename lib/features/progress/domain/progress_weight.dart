import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_anticipation_calculator.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

/// Weight trend of a period with the goal starts and the forecast for the
/// goal.
@immutable
class ProgressWeight {
  /// Creates the weight progress.
  const new({
    required this.trend,
    required this.goalStarts,
    required this.projectedGoalDate,
    required this.isGoalReached,
  });

  /// Adds the goal of [profile] and its forecast to [trend].
  factory fromTrend({
    required RecentWeightTrend trend,
    required List<ProgressGoalStart> goalStarts,
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
      goalStarts: goalStarts,
      projectedGoalDate: projection == null || projection.isAchieved
          ? null
          : projection.projectedDate,
      isGoalReached: projection?.isAchieved ?? false,
    );
  }

  /// Weigh-ins and trend weight per day, oldest first.
  final RecentWeightTrend trend;

  /// First day of each goal in the chart, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// Day on which the trend reaches the goal weight, or `null` when it does
  /// not move towards it or there is no goal weight.
  final DateTime? projectedGoalDate;

  /// Whether the trend weight already reached the goal weight.
  final bool isGoalReached;
}
