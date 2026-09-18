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
