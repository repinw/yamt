import 'package:flutter/foundation.dart';

/// Fully resolved nutrition target for a specific day, combining calories
/// and macros.
@immutable
class DailyNutritionTarget {
  /// Creates a daily nutrition target.
  const new({
    required this.date,
    required this.goalKcal,
    required this.carbsGrams,
    required this.proteinGrams,
    required this.fatGrams,
    this.baseGoalKcal = 0.0,
    this.isTrainingDay = false,
    this.isPauseDay = false,
  });

  /// The calendar date for this target.
  final DateTime date;

  /// Effective daily calorie goal (including cycling offset and carryover).
  final double goalKcal;

  /// Carbs target in grams (mind. 100g floor protected).
  final double carbsGrams;

  /// Protein target in grams.
  final double proteinGrams;

  /// Fat target in grams.
  final double fatGrams;

  /// Base calorie goal before cycling offset and carryover.
  final double baseGoalKcal;

  /// Whether this day is configured as a training day.
  final bool isTrainingDay;

  /// Whether this day is a pause day.
  final bool isPauseDay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyNutritionTarget &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          goalKcal == other.goalKcal &&
          carbsGrams == other.carbsGrams &&
          proteinGrams == other.proteinGrams &&
          fatGrams == other.fatGrams &&
          baseGoalKcal == other.baseGoalKcal &&
          isTrainingDay == other.isTrainingDay &&
          isPauseDay == other.isPauseDay;

  @override
  int get hashCode => Object.hash(
    date,
    goalKcal,
    carbsGrams,
    proteinGrams,
    fatGrams,
    baseGoalKcal,
    isTrainingDay,
    isPauseDay,
  );

  @override
  String toString() =>
      'DailyNutritionTarget(date: $date, goalKcal: $goalKcal, '
      'carbs: ${carbsGrams}g, protein: ${proteinGrams}g, fat: ${fatGrams}g)';
}
