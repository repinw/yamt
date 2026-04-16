/// Defines health workout session.
class HealthWorkoutSession {
  /// The health workout session.
  const HealthWorkoutSession({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.durationMinutes,
    required this.activityLabel,
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

  /// The activity label.
  final String? activityLabel;

  /// The source name.
  final String? sourceName;

  /// The total calories.
  final int? totalCalories;

  /// The total steps.
  final int? totalSteps;

  /// Copy with.
  HealthWorkoutSession copyWith({
    String? id,
    DateTime? start,
    DateTime? endExclusive,
    double? durationMinutes,
    String? activityLabel,
    String? sourceName,
    int? totalCalories,
    int? totalSteps,
  }) {
    return HealthWorkoutSession(
      id: id ?? this.id,
      start: start ?? this.start,
      endExclusive: endExclusive ?? this.endExclusive,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      activityLabel: activityLabel ?? this.activityLabel,
      sourceName: sourceName ?? this.sourceName,
      totalCalories: totalCalories ?? this.totalCalories,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

/// Defines health active energy sample.
class HealthActiveEnergySample {
  /// The health active energy sample.
  const HealthActiveEnergySample({
    required this.startAt,
    required this.endAt,
    required this.numericValue,
  });

  /// The start at.
  final DateTime startAt;

  /// The end at.
  final DateTime endAt;

  /// The numeric value.
  final num numericValue;
}

/// Merge workout calories.
HealthWorkoutSession mergeWorkoutCalories({
  required HealthWorkoutSession workout,
  required List<HealthActiveEnergySample> activeEnergySamples,
}) {
  final mergedCalories = activeEnergySamples.fold<double>(
    0,
    (sum, sample) =>
        sum + _activeEnergyOverlapValue(sample: sample, workout: workout),
  );
  if (mergedCalories > 0) {
    return workout.copyWith(totalCalories: mergedCalories.round());
  }
  return workout;
}

double _activeEnergyOverlapValue({
  required HealthActiveEnergySample sample,
  required HealthWorkoutSession workout,
}) {
  final overlapStart = sample.startAt.isAfter(workout.start)
      ? sample.startAt
      : workout.start;
  final overlapEnd = sample.endAt.isBefore(workout.endExclusive)
      ? sample.endAt
      : workout.endExclusive;
  if (!overlapEnd.isAfter(overlapStart)) {
    return 0;
  }

  final sampleDurationMs = sample.endAt
      .difference(sample.startAt)
      .inMilliseconds;
  if (sampleDurationMs <= 0) {
    return sample.numericValue.toDouble();
  }

  final overlapMs = overlapEnd.difference(overlapStart).inMilliseconds;
  if (overlapMs <= 0) {
    return 0;
  }

  return sample.numericValue.toDouble() * overlapMs / sampleDurationMs;
}
