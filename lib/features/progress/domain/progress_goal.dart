import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';

/// The current goal: where the user wants to go, how far the weight got,
/// and the daily calories and macros.
@immutable
class ProgressGoal {
  /// Creates the goal progress.
  const new({
    required this.profile,
    required this.currentWeightKg,
    required this.dailyKcalGoal,
    required this.macroTarget,
  });

  /// Body data and weight goal from the calculator, or `null` without one.
  final CalorieCalculatorProfile? profile;

  /// The weight that counts now: the trend weight, else the last weigh-in.
  final double? currentWeightKg;

  /// Base daily calorie goal, or `null` when no goal is set.
  final double? dailyKcalGoal;

  /// Protein, carbs, and fat for [dailyKcalGoal], or `null` without a goal.
  final DailyNutritionTarget? macroTarget;

  /// Kilograms left to the target weight, or `null` without a target.
  double? get kgToTarget {
    final target = profile?.targetWeightKg;
    final current = currentWeightKg;
    if (target == null || current == null) return null;
    return (current - target).abs();
  }

  /// Kilograms the weight moved away from the target past the start weight,
  /// or `null` while it is on the way or without a target.
  ///
  /// Positive means above the start weight, negative below it.
  double? get kgPastStart {
    final start = profile?.weightKg;
    final target = profile?.targetWeightKg;
    final current = currentWeightKg;
    if (start == null || target == null || current == null) return null;
    final awayFromTarget = target < start ? current > start : current < start;
    return awayFromTarget ? current - start : null;
  }

  /// Share of the way from the start weight to the target weight, 0 to 1.
  double? get share {
    final start = profile?.weightKg;
    final target = profile?.targetWeightKg;
    final current = currentWeightKg;
    if (start == null || target == null || current == null) return null;
    final distance = start - target;
    if (distance == 0) return 1;
    return ((start - current) / distance).clamp(0, 1).toDouble();
  }
}
