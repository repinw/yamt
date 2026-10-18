/// Data for the diary weight card.
class DiaryActivityWeightData {
  /// Creates diary weight data.
  const new({
    required this.profileWeightKg,
    required this.hasSelectedDayWeight,
    required this.weightTrend,
  });

  /// Profile weight from the calorie calculator.
  final double? profileWeightKg;

  /// Whether the selected day has a real saved weight point.
  final bool hasSelectedDayWeight;

  /// Seven day weight trend.
  final List<double?> weightTrend;
}
