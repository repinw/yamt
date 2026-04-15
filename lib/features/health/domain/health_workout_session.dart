class HealthWorkoutSession {
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

  final String id;
  final DateTime start;
  final DateTime endExclusive;
  final double durationMinutes;
  final String? activityLabel;
  final String? sourceName;
  final int? totalCalories;
  final int? totalSteps;

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

class HealthActiveEnergySample {
  const HealthActiveEnergySample({
    required this.startAt,
    required this.endAt,
    required this.numericValue,
  });

  final DateTime startAt;
  final DateTime endAt;
  final num numericValue;
}

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
