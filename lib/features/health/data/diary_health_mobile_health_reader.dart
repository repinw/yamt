import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/data/diary_health_mobile_config.dart';
import 'package:yamt/features/health/data/diary_health_read_queue.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

/// Reads raw Health data and converts it into diary domain models.
class DiaryHealthMobileHealthReader {
  /// Creates a Health reader.
  const DiaryHealthMobileHealthReader({
    required Health health,
    required DiaryHealthReadQueue readQueue,
    required Future<void> Function() ensureConfigured,
  }) : _health = health,
       _readQueue = readQueue,
       _ensureConfigured = ensureConfigured;

  final Health _health;
  final DiaryHealthReadQueue _readQueue;
  final Future<void> Function() _ensureConfigured;

  /// Reads derived day data from Health.
  Future<DiaryHealthDayData> loadDayData({
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) {
    return _readQueue.run(() async {
      await _ensureConfigured();
      return _loadDayDataFromHealth(
        dayStart: dayStart,
        dayEnd: dayEnd,
        normalizedUserHeightCm: normalizedUserHeightCm,
      );
    });
  }

  /// Reads aggregate activity trend days from Health.
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _readQueue.run(() async {
      await _ensureConfigured();
      final points = await _health.getHealthIntervalDataFromTypes(
        startDate: startInclusive,
        endDate: endExclusive,
        types: activityTrendQueryTypes,
        interval: activityTrendIntervalSeconds,
      );
      return _buildActivityTrendDays(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        points: points,
      );
    });
  }

  Future<DiaryHealthDayData> _loadDayDataFromHealth({
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) async {
    final totalSteps =
        await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;
    final workoutPoints = await _health.getHealthDataFromTypes(
      types: workoutQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergyPoints = await _health.getHealthDataFromTypes(
      types: activeEnergyQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergySamples = activeEnergyPoints
        .map(_buildActiveEnergySample)
        .whereType<HealthActiveEnergySample>()
        .toList(growable: false);
    final baseWorkouts = workoutPoints
        .map(
          (point) => _resolveWorkoutBase(
            point: point,
            userHeightCm: normalizedUserHeightCm,
          ),
        )
        .toList(growable: false);
    final resolvedWorkouts = _mergeWorkoutCaloriesWithoutDoubleCounting(
      workouts: baseWorkouts,
      activeEnergySamples: activeEnergySamples,
    );
    final unassignedActiveEnergySegments = <HealthEnergySegment>[];
    for (final point in activeEnergyPoints) {
      unassignedActiveEnergySegments.addAll(
        await _buildUnassignedActiveEnergySegments(
          point: point,
          dayStart: dayStart,
          dayEnd: dayEnd,
          workouts: resolvedWorkouts,
        ),
      );
    }
    final workouts = resolvedWorkouts.toList(growable: false)
      ..sort((left, right) => right.start.compareTo(left.start));
    final activeEnergySegments = unassignedActiveEnergySegments.toList(
      growable: false,
    )..sort((left, right) => right.start.compareTo(left.start));

    _logHealthDayData(
      dayStart: dayStart,
      totalSteps: totalSteps,
      workoutPoints: workoutPoints,
      activeEnergyPoints: activeEnergyPoints,
      workouts: workouts,
      unassignedActiveEnergySegments: activeEnergySegments,
    );

    return DiaryHealthDayData(
      totalSteps: totalSteps,
      workouts: List<HealthWorkoutSession>.unmodifiable(workouts),
      unassignedActiveEnergySegments: List<HealthEnergySegment>.unmodifiable(
        activeEnergySegments,
      ),
    );
  }

  void _logHealthDayData({
    required DateTime dayStart,
    required int totalSteps,
    required List<HealthDataPoint> workoutPoints,
    required List<HealthDataPoint> activeEnergyPoints,
    required List<HealthWorkoutSession> workouts,
    required List<HealthEnergySegment> unassignedActiveEnergySegments,
  }) {
    log(
      'Read day data. '
      'day=${dayStart.toIso8601String()} '
      'steps=$totalSteps '
      'workout_points=${workoutPoints.length} '
      'active_energy_points=${activeEnergyPoints.length} '
      'workouts=${workouts.length} '
      'workout_kcal=${_sumWorkoutCalories(workouts)} '
      'unassigned_active_energy_segments='
      '${unassignedActiveEnergySegments.length} '
      'unassigned_active_energy_kcal='
      '${_sumUnassignedActiveEnergyCalories(unassignedActiveEnergySegments)} '
      'workout_steps=${_sumWorkoutSteps(workouts)} '
      'workout_sources=${_sourceNames(workoutPoints)} '
      'active_energy_sources=${_sourceNames(activeEnergyPoints)}',
      name: diaryHealthLogName,
    );
    if (totalSteps > 0 && workoutPoints.isEmpty && activeEnergyPoints.isEmpty) {
      log(
        'Read day data has steps only. '
        'day=${dayStart.toIso8601String()} '
        'Health Connect returned no workouts or active energy.',
        name: diaryHealthLogName,
      );
    }
  }

  int _sumWorkoutCalories(List<HealthWorkoutSession> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.totalCalories ?? 0),
    );
  }

  int _sumWorkoutSteps(List<HealthWorkoutSession> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.totalSteps ?? 0),
    );
  }

  int _sumUnassignedActiveEnergyCalories(List<HealthEnergySegment> segments) {
    return segments.fold<int>(
      0,
      (sum, segment) => sum + segment.totalCalories,
    );
  }

  String _sourceNames(List<HealthDataPoint> points) {
    final sourceNames =
        points
            .map((point) => point.sourceName)
            .where((sourceName) => sourceName.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return sourceNames.isEmpty ? '[]' : sourceNames.join(',');
  }

  List<DiaryHealthActivityTrendDay> _buildActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
    required List<HealthDataPoint> points,
  }) {
    final stepsByDay = <String, int>{};
    final activeEnergyByDay = <String, int>{};
    for (final point in points) {
      final value = _numericHealthValue(point)?.round();
      if (value == null || value <= 0) {
        continue;
      }
      final day = normalizeLocalDay(point.dateFrom.toLocal());
      if (day.isBefore(startInclusive) || !day.isBefore(endExclusive)) {
        continue;
      }
      final key = localDayKey(day);
      if (point.type == HealthDataType.STEPS) {
        stepsByDay[key] = (stepsByDay[key] ?? 0) + value;
      } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        activeEnergyByDay[key] = (activeEnergyByDay[key] ?? 0) + value;
      }
    }

    final days = <DiaryHealthActivityTrendDay>[];
    for (
      var day = startInclusive;
      day.isBefore(endExclusive);
      day = nextLocalDay(day)
    ) {
      final key = localDayKey(day);
      days.add(
        DiaryHealthActivityTrendDay(
          day: day,
          totalSteps: stepsByDay[key] ?? 0,
          activeEnergyKcal: activeEnergyByDay[key] ?? 0,
        ),
      );
    }
    return List<DiaryHealthActivityTrendDay>.unmodifiable(days);
  }

  HealthWorkoutSession _resolveWorkoutBase({
    required HealthDataPoint point,
    required double? userHeightCm,
  }) {
    return _backfillWorkoutSteps(
      workout: _buildWorkoutSession(point),
      point: point,
      userHeightCm: userHeightCm,
    );
  }

  List<HealthWorkoutSession> _mergeWorkoutCaloriesWithoutDoubleCounting({
    required List<HealthWorkoutSession> workouts,
    required List<HealthActiveEnergySample> activeEnergySamples,
  }) {
    final allocatedIntervals = <_DateTimeInterval>[];
    final orderedWorkouts = workouts.toList(growable: false)
      ..sort(_compareWorkoutStartThenEnd);
    final resolvedWorkouts = <HealthWorkoutSession>[];

    for (final workout in orderedWorkouts) {
      final workoutInterval = _DateTimeInterval(
        workout.start,
        workout.endExclusive,
      );
      final availableIntervals = _subtractIntervals(
        intervals: <_DateTimeInterval>[workoutInterval],
        blockers: allocatedIntervals,
      );
      final visibleCalories = _activeEnergyValueForIntervals(
        samples: activeEnergySamples,
        intervals: availableIntervals,
      );
      final overlappedCalories = _activeEnergyValueForIntervals(
        samples: activeEnergySamples,
        intervals: <_DateTimeInterval>[workoutInterval],
      );

      if (visibleCalories > 0) {
        resolvedWorkouts.add(
          workout.copyWith(totalCalories: visibleCalories.round()),
        );
      } else if (overlappedCalories > 0) {
        resolvedWorkouts.add(_copyWorkoutWithTotalCalories(workout, null));
      } else {
        resolvedWorkouts.add(workout);
      }
      allocatedIntervals.add(workoutInterval);
    }

    return resolvedWorkouts;
  }

  HealthWorkoutSession _buildWorkoutSession(HealthDataPoint point) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    final summarySteps = _positiveWorkoutSummarySteps(point.workoutSummary);
    return HealthWorkoutSession(
      id: point.uuid.isNotEmpty
          ? point.uuid
          : '${point.sourceId}:'
                '${point.dateFrom.toUtc().millisecondsSinceEpoch}',
      start: point.dateFrom.toLocal(),
      endExclusive: point.dateTo.toLocal(),
      durationMinutes: point.dateTo.difference(point.dateFrom).inSeconds / 60,
      activityLabel: workoutValue == null
          ? null
          : _formatWorkoutActivityLabel(workoutValue.workoutActivityType),
      sourceName: point.sourceName.isEmpty ? null : point.sourceName,
      totalCalories: workoutValue?.totalEnergyBurned,
      totalSteps: _resolveInitialWorkoutSteps(
        workoutValueSteps: workoutValue?.totalSteps,
        summarySteps: summarySteps,
      ),
    );
  }

  HealthWorkoutSession _backfillWorkoutSteps({
    required HealthWorkoutSession workout,
    required HealthDataPoint point,
    required double? userHeightCm,
  }) {
    if (!_needsWorkoutStepBackfill(point: point, workout: workout)) {
      return workout;
    }

    final estimatedSteps = _estimateStepsFromWorkoutDistance(
      point,
      userHeightCm: userHeightCm,
    );
    if (estimatedSteps == null || estimatedSteps <= 0) {
      return workout;
    }

    return workout.copyWith(totalSteps: estimatedSteps);
  }

  bool _needsWorkoutStepBackfill({
    required HealthDataPoint point,
    required HealthWorkoutSession workout,
  }) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    if (workoutValue == null) {
      return false;
    }
    if (!stepBasedWorkoutTypes.contains(workoutValue.workoutActivityType)) {
      return false;
    }
    final totalSteps = workout.totalSteps;
    return totalSteps == null || totalSteps <= 0;
  }

  int? _resolveInitialWorkoutSteps({
    required int? workoutValueSteps,
    required int? summarySteps,
  }) {
    final positiveWorkoutValueSteps = _positiveStepCount(workoutValueSteps);
    return positiveWorkoutValueSteps ?? summarySteps;
  }

  int? _positiveStepCount(int? value) {
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  int? _positiveWorkoutSummarySteps(WorkoutSummary? workoutSummary) {
    if (workoutSummary == null) {
      return null;
    }
    final roundedSteps = workoutSummary.totalSteps.round();
    return roundedSteps > 0 ? roundedSteps : null;
  }

  HealthActiveEnergySample? _buildActiveEnergySample(HealthDataPoint point) {
    final numericValue = _numericHealthValue(point);
    if (numericValue == null) {
      return null;
    }
    return HealthActiveEnergySample(
      startAt: point.dateFrom.toLocal(),
      endAt: point.dateTo.toLocal(),
      numericValue: numericValue,
    );
  }

  Future<List<HealthEnergySegment>> _buildUnassignedActiveEnergySegments({
    required HealthDataPoint point,
    required DateTime dayStart,
    required DateTime dayEnd,
    required List<HealthWorkoutSession> workouts,
  }) async {
    final sample = _buildActiveEnergySample(point);
    if (sample == null) {
      return const <HealthEnergySegment>[];
    }

    final clippedStart = sample.startAt.isAfter(dayStart)
        ? sample.startAt
        : dayStart;
    final clippedEnd = sample.endAt.isBefore(dayEnd) ? sample.endAt : dayEnd;
    if (!clippedEnd.isAfter(clippedStart)) {
      return const <HealthEnergySegment>[];
    }

    final overlappingWorkouts =
        workouts
            .where(
              (workout) =>
                  workout.endExclusive.isAfter(clippedStart) &&
                  workout.start.isBefore(clippedEnd),
            )
            .toList(growable: false)
          ..sort((left, right) => left.start.compareTo(right.start));

    final unassignedSegments = <HealthEnergySegment>[];
    var cursor = clippedStart;
    var segmentIndex = 0;

    for (final workout in overlappingWorkouts) {
      final overlapStart = workout.start.isAfter(clippedStart)
          ? workout.start
          : clippedStart;
      final overlapEnd = workout.endExclusive.isBefore(clippedEnd)
          ? workout.endExclusive
          : clippedEnd;
      if (!overlapEnd.isAfter(overlapStart)) {
        continue;
      }
      if (overlapStart.isAfter(cursor)) {
        final segment = await _buildUnassignedActiveEnergySegment(
          point: point,
          sample: sample,
          start: cursor,
          endExclusive: overlapStart,
          segmentIndex: segmentIndex,
        );
        if (segment != null) {
          unassignedSegments.add(segment);
          segmentIndex += 1;
        }
      }
      if (overlapEnd.isAfter(cursor)) {
        cursor = overlapEnd;
      }
      if (!clippedEnd.isAfter(cursor)) {
        break;
      }
    }

    if (clippedEnd.isAfter(cursor)) {
      final segment = await _buildUnassignedActiveEnergySegment(
        point: point,
        sample: sample,
        start: cursor,
        endExclusive: clippedEnd,
        segmentIndex: segmentIndex,
      );
      if (segment != null) {
        unassignedSegments.add(segment);
      }
    }

    return unassignedSegments;
  }

  Future<HealthEnergySegment?> _buildUnassignedActiveEnergySegment({
    required HealthDataPoint point,
    required HealthActiveEnergySample sample,
    required DateTime start,
    required DateTime endExclusive,
    required int segmentIndex,
  }) async {
    final calories = _activeEnergyValueForRange(
      sample: sample,
      start: start,
      endExclusive: endExclusive,
    );
    if (calories <= 0) {
      return null;
    }
    final totalSteps = await _health.getTotalStepsInInterval(
      start,
      endExclusive,
    );
    if (!_shouldCountUnassignedActiveEnergy(
      calories: calories,
      totalSteps: totalSteps,
      start: start,
      endExclusive: endExclusive,
    )) {
      return null;
    }

    return HealthEnergySegment(
      id: _unassignedActiveEnergySegmentId(
        point: point,
        start: start,
        segmentIndex: segmentIndex,
      ),
      start: start,
      endExclusive: endExclusive,
      durationMinutes: endExclusive.difference(start).inSeconds / 60,
      sourceName: point.sourceName.isEmpty ? null : point.sourceName,
      totalCalories: calories.round(),
      totalSteps: _positiveStepCount(totalSteps),
    );
  }

  bool _shouldCountUnassignedActiveEnergy({
    required double calories,
    required int? totalSteps,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    if (calories <= 0) {
      return false;
    }
    if (totalSteps != null && totalSteps > 0) {
      return true;
    }

    final durationMinutes =
        endExclusive.difference(start).inMilliseconds / 60000;
    if (durationMinutes <= 0) {
      return false;
    }
    return calories / durationMinutes >= minimumUnassignedActivityKcalPerMinute;
  }

  String _unassignedActiveEnergySegmentId({
    required HealthDataPoint point,
    required DateTime start,
    required int segmentIndex,
  }) {
    final baseId = point.uuid.isNotEmpty
        ? point.uuid
        : '${point.sourceId}:${start.toUtc().millisecondsSinceEpoch}';
    return 'unassigned-active-energy:$baseId:$segmentIndex';
  }

  int? _estimateStepsFromWorkoutDistance(
    HealthDataPoint point, {
    required double? userHeightCm,
  }) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    if (workoutValue == null || workoutValue.totalDistance == null) {
      return null;
    }

    final distanceMeters = _distanceToMeters(
      distance: workoutValue.totalDistance!,
      unit: workoutValue.totalDistanceUnit,
    );
    if (distanceMeters == null || distanceMeters <= 0) {
      return null;
    }

    final stepLengthMeters = _personalizeStepLengthMeters(
      defaultStepLengthMeters: _defaultStepLengthMetersForWorkoutType(
        workoutValue.workoutActivityType,
      ),
      userHeightCm: userHeightCm,
    );
    final estimatedSteps = (distanceMeters / stepLengthMeters).round();
    return estimatedSteps > 0 ? estimatedSteps : null;
  }

  double? _distanceToMeters({
    required int distance,
    required HealthDataUnit? unit,
  }) {
    return switch (unit) {
      HealthDataUnit.CENTIMETER => distance / 100,
      HealthDataUnit.FOOT => distance * 0.3048,
      HealthDataUnit.INCH => distance * 0.0254,
      HealthDataUnit.METER => distance.toDouble(),
      HealthDataUnit.MILE => distance * 1609.344,
      HealthDataUnit.YARD => distance * 0.9144,
      _ => null,
    };
  }

  double _defaultStepLengthMetersForWorkoutType(
    HealthWorkoutActivityType type,
  ) {
    return switch (type) {
      HealthWorkoutActivityType.RUNNING ||
      HealthWorkoutActivityType.RUNNING_TREADMILL ||
      HealthWorkoutActivityType.TRACK_AND_FIELD ||
      HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE => 0.85,
      HealthWorkoutActivityType.STAIRS ||
      HealthWorkoutActivityType.STAIR_CLIMBING ||
      HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE ||
      HealthWorkoutActivityType.STEP_TRAINING => 0.6,
      _ => 0.75,
    };
  }

  double _personalizeStepLengthMeters({
    required double defaultStepLengthMeters,
    required double? userHeightCm,
  }) {
    if (userHeightCm == null) {
      return defaultStepLengthMeters;
    }

    return defaultStepLengthMeters *
        (userHeightCm / defaultCalculatorProfileHeightCm);
  }

  String _formatWorkoutActivityLabel(HealthWorkoutActivityType type) {
    return type.name.split('_').map(_capitalizeWord).join(' ');
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) {
      return word;
    }
    final lowerCaseWord = word.toLowerCase();
    return '${lowerCaseWord[0].toUpperCase()}${lowerCaseWord.substring(1)}';
  }
}

num? _numericHealthValue(HealthDataPoint point) {
  final value = point.value;
  return switch (value) {
    NumericHealthValue(:final numericValue) => numericValue,
    _ => null,
  };
}

double _activeEnergyValueForRange({
  required HealthActiveEnergySample sample,
  required DateTime start,
  required DateTime endExclusive,
}) {
  final overlapStart = start.isAfter(sample.startAt) ? start : sample.startAt;
  final overlapEnd = endExclusive.isBefore(sample.endAt)
      ? endExclusive
      : sample.endAt;
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

int _compareWorkoutStartThenEnd(
  HealthWorkoutSession left,
  HealthWorkoutSession right,
) {
  final startComparison = left.start.compareTo(right.start);
  if (startComparison != 0) {
    return startComparison;
  }
  return left.endExclusive.compareTo(right.endExclusive);
}

HealthWorkoutSession _copyWorkoutWithTotalCalories(
  HealthWorkoutSession workout,
  int? totalCalories,
) {
  return HealthWorkoutSession(
    id: workout.id,
    start: workout.start,
    endExclusive: workout.endExclusive,
    durationMinutes: workout.durationMinutes,
    activityLabel: workout.activityLabel,
    sourceName: workout.sourceName,
    totalCalories: totalCalories,
    totalSteps: workout.totalSteps,
  );
}

double _activeEnergyValueForIntervals({
  required List<HealthActiveEnergySample> samples,
  required List<_DateTimeInterval> intervals,
}) {
  var total = 0.0;
  for (final sample in samples) {
    for (final interval in intervals) {
      total += _activeEnergyValueForRange(
        sample: sample,
        start: interval.start,
        endExclusive: interval.endExclusive,
      );
    }
  }
  return total;
}

List<_DateTimeInterval> _subtractIntervals({
  required List<_DateTimeInterval> intervals,
  required List<_DateTimeInterval> blockers,
}) {
  var remaining = intervals;
  for (final blocker in blockers) {
    remaining = remaining
        .expand((interval) => interval.subtract(blocker))
        .toList(growable: false);
  }
  return remaining;
}

class _DateTimeInterval {
  const _DateTimeInterval(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  List<_DateTimeInterval> subtract(_DateTimeInterval blocker) {
    final overlapStart = blocker.start.isAfter(start) ? blocker.start : start;
    final overlapEnd = blocker.endExclusive.isBefore(endExclusive)
        ? blocker.endExclusive
        : endExclusive;
    if (!overlapEnd.isAfter(overlapStart)) {
      return <_DateTimeInterval>[this];
    }

    final remaining = <_DateTimeInterval>[];
    if (overlapStart.isAfter(start)) {
      remaining.add(_DateTimeInterval(start, overlapStart));
    }
    if (endExclusive.isAfter(overlapEnd)) {
      remaining.add(_DateTimeInterval(overlapEnd, endExclusive));
    }
    return remaining;
  }
}
