/// Defines unassigned health energy that may count as activity.
class HealthEnergySegment {
  /// Creates a health energy segment.
  const HealthEnergySegment({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.durationMinutes,
    required this.sourceName,
    required this.totalCalories,
    required this.totalSteps,
  });

  /// The id.
  final String id;

  /// The start.
  final DateTime start;

  /// The end exclusive.
  final DateTime endExclusive;

  /// The duration minutes.
  final double durationMinutes;

  /// The source name.
  final String? sourceName;

  /// The total calories.
  final int totalCalories;

  /// The total steps.
  final int? totalSteps;

  @override
  String toString() {
    return 'HealthEnergySegment('
        'id: $id, '
        'start: $start, '
        'endExclusive: $endExclusive, '
        'durationMinutes: $durationMinutes, '
        'sourceName: $sourceName, '
        'totalCalories: $totalCalories, '
        'totalSteps: $totalSteps'
        ')';
  }
}
