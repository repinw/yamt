import 'dart:math' as math;

/// Fraction of workout calories granted as a temporary bootstrap bonus.
const bootstrapWorkoutBonusFraction = 0.35;

/// Maximum temporary bootstrap workout bonus for a single day.
const bootstrapWorkoutBonusMaxKcal = 300.0;

/// Calculates the learned daily activity bonus after the first weekly check-in.
double calculateLearnedActivityBonusKcal({
  required int todayActiveKcal,
  required double averageActiveKcal,
}) {
  return math.max<double>(0, todayActiveKcal - averageActiveKcal);
}

/// Calculates the temporary workout bonus before the first weekly check-in.
double calculateBootstrapWorkoutBonusKcal({
  required int workoutCalories,
}) {
  if (workoutCalories <= 0) {
    return 0;
  }
  return math
      .min<double>(
        bootstrapWorkoutBonusMaxKcal,
        workoutCalories * bootstrapWorkoutBonusFraction,
      )
      .roundToDouble();
}
