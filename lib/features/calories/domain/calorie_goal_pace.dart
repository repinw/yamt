/// Slowest pace the goal pickers offer, in kilograms per week.
const minimumGoalPaceKgPerWeek = 0.05;

/// Fastest pace the goal pickers offer, in kilograms per week.
const maximumGoalPaceKgPerWeek = 1.5;

/// Distance between two pace picker items, in kilograms per week.
const goalPaceStepKgPerWeek = 0.05;

/// Pace the goal pickers start on, in kilograms per week.
const defaultGoalPaceKgPerWeek = 0.5;

/// Rounds [paceKgPerWeek] to the nearest step the goal pickers offer.
double snapGoalPace(double paceKgPerWeek) {
  final steps =
      ((paceKgPerWeek - minimumGoalPaceKgPerWeek) / goalPaceStepKgPerWeek)
          .round();
  final maxSteps =
      ((maximumGoalPaceKgPerWeek - minimumGoalPaceKgPerWeek) /
              goalPaceStepKgPerWeek)
          .round();
  final snapped =
      minimumGoalPaceKgPerWeek +
      steps.clamp(0, maxSteps) * goalPaceStepKgPerWeek;
  return double.parse(snapped.toStringAsFixed(2));
}

/// Estimates the day the target weight is reached at the configured pace.
///
/// Returns `null` when the pace is zero, when the target equals the current
/// weight, or when the values are otherwise not usable for an estimate.
DateTime? estimateGoalReachedDate({
  required double currentWeightKg,
  required double targetWeightKg,
  required double goalSpeedKgPerWeek,
  required DateTime today,
}) {
  if (goalSpeedKgPerWeek <= 0) {
    return null;
  }
  final remainingKg = (targetWeightKg - currentWeightKg).abs();
  if (remainingKg <= 0) {
    return null;
  }
  final days = (remainingKg / goalSpeedKgPerWeek * DateTime.daysPerWeek).ceil();
  return DateTime(today.year, today.month, today.day + days);
}
