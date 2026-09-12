import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';

/// Represents one goal cycle or the aggregate "all goals" view.
class TdeeAnalyticsGoalCycle {
  /// Creates a goal cycle descriptor.
  const TdeeAnalyticsGoalCycle({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.isAllGoals = false,
    this.goalMode,
    this.startWeightKg,
    this.targetWeightKg,
    this.goalSpeedKgPerWeek,
    this.initialGoalKcal,
    this.estimatedEndDate,
    this.reachedDate,
    this.endWeightKg,
  });

  /// Unique identifier (e.g. ISO date or 'all').
  final String id;

  /// Localized title.
  final String title;

  /// Start date of this cycle.
  final DateTime startDate;

  /// End date of this cycle, or null if currently active.
  final DateTime? endDate;

  /// Whether this represents the overall aggregate.
  final bool isAllGoals;

  /// Goal mode (lose, maintain, gain).
  final CalorieGoalMode? goalMode;

  /// Starting weight at goal creation.
  final double? startWeightKg;

  /// Desired target weight.
  final double? targetWeightKg;

  /// Planned weight loss/gain rate per week in kg.
  final double? goalSpeedKgPerWeek;

  /// Initial daily calorie target.
  final double? initialGoalKcal;

  /// Planned end date derived from target/speed or chosen for maintenance.
  final DateTime? estimatedEndDate;

  /// Date on which the target weight was first reached.
  final DateTime? reachedDate;

  /// Actual ending weight, or the configured target for an active goal.
  final double? endWeightKg;

  /// Whether this cycle is active today.
  bool get isActive => endDate == null && !isAllGoals;
}
