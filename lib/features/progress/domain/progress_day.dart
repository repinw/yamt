import 'package:meta/meta.dart';

/// Kilocalories in one gram of protein or carbohydrate.
const double kcalPerGramProteinOrCarbs = 4;

/// Kilocalories in one gram of fat.
const double kcalPerGramFat = 9;

/// What was eaten on one day, against the goal of that day.
@immutable
class ProgressDay {
  /// Creates one progress day.
  const new({
    required this.day,
    required this.eatenKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.goalKcal,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    required this.isTrainingDay,
    required this.isPauseDay,
    required this.hasEntries,
    required this.isFuture,
  });

  /// The diary day.
  final DateTime day;

  /// Eaten kilocalories.
  final double eatenKcal;

  /// Eaten protein in grams.
  final double proteinGrams;

  /// Eaten carbohydrates in grams.
  final double carbsGrams;

  /// Eaten fat in grams.
  final double fatGrams;

  /// Calorie goal of the day.
  final double goalKcal;

  /// Protein goal of the day in grams.
  final double proteinGoalGrams;

  /// Carbohydrate goal of the day in grams.
  final double carbsGoalGrams;

  /// Fat goal of the day in grams.
  final double fatGoalGrams;

  /// Whether the day is a training day.
  final bool isTrainingDay;

  /// Whether the day is a pause day that does not count.
  final bool isPauseDay;

  /// Whether anything was logged on the day.
  final bool hasEntries;

  /// Whether the day is still ahead.
  final bool isFuture;

  /// Whether the day counts for averages: past or today, logged, no pause.
  bool get counts => !isFuture && hasEntries && !isPauseDay;

  /// Protein in kilocalories.
  double get proteinKcal => proteinGrams * kcalPerGramProteinOrCarbs;

  /// Carbohydrates in kilocalories.
  double get carbsKcal => carbsGrams * kcalPerGramProteinOrCarbs;

  /// Fat in kilocalories.
  double get fatKcal => fatGrams * kcalPerGramFat;
}
