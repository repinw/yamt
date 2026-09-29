import 'package:meta/meta.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';

/// Daily averages over the counting days of a period.
@immutable
class ProgressAverage {
  /// Creates an average.
  const new({
    required this.dayCount,
    required this.eatenKcal,
    required this.goalKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
  });

  /// Averages the days of [days] that count (see [ProgressDay.counts]).
  factory of(Iterable<ProgressDay> days) {
    final counted = days.where((day) => day.counts).toList(growable: false);
    final count = counted.length;
    double average(double Function(ProgressDay day) value) {
      if (count == 0) return 0;
      return counted.fold<double>(0, (sum, day) => sum + value(day)) / count;
    }

    return ProgressAverage(
      dayCount: count,
      eatenKcal: average((day) => day.eatenKcal),
      goalKcal: average((day) => day.goalKcal),
      proteinGrams: average((day) => day.proteinGrams),
      carbsGrams: average((day) => day.carbsGrams),
      fatGrams: average((day) => day.fatGrams),
      proteinGoalGrams: average((day) => day.proteinGoalGrams),
      carbsGoalGrams: average((day) => day.carbsGoalGrams),
      fatGoalGrams: average((day) => day.fatGoalGrams),
    );
  }

  /// Number of days in the average.
  final int dayCount;

  /// Eaten kilocalories per day.
  final double eatenKcal;

  /// Calorie goal per day.
  final double goalKcal;

  /// Eaten protein per day in grams.
  final double proteinGrams;

  /// Eaten carbohydrates per day in grams.
  final double carbsGrams;

  /// Eaten fat per day in grams.
  final double fatGrams;

  /// Protein goal per day in grams.
  final double proteinGoalGrams;

  /// Carbohydrate goal per day in grams.
  final double carbsGoalGrams;

  /// Fat goal per day in grams.
  final double fatGoalGrams;
}
