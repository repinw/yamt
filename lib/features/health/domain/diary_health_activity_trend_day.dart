/// Aggregated Health Connect activity data for one diary trend day.
class DiaryHealthActivityTrendDay {
  /// Creates a trend day.
  const DiaryHealthActivityTrendDay({
    required this.day,
    required this.totalSteps,
    required this.activeEnergyKcal,
  });

  /// The normalized diary day.
  final DateTime day;

  /// Aggregate step count for the day.
  final int totalSteps;

  /// Aggregate active energy for the day.
  final int activeEnergyKcal;
}
