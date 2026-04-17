import 'package:health/health.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

const _workoutQueryTypes = <HealthDataType>[HealthDataType.WORKOUT];
const _activeEnergyQueryTypes = <HealthDataType>[
  HealthDataType.ACTIVE_ENERGY_BURNED,
];
const _defaultCalculatorProfileHeightCm = 180.0;
const _minPersonalizedHeightCm = 120.0;
const _maxPersonalizedHeightCm = 250.0;
const _stepBasedWorkoutTypes = <HealthWorkoutActivityType>{
  HealthWorkoutActivityType.HIKING,
  HealthWorkoutActivityType.RUNNING,
  HealthWorkoutActivityType.RUNNING_TREADMILL,
  HealthWorkoutActivityType.STAIRS,
  HealthWorkoutActivityType.STAIR_CLIMBING,
  HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE,
  HealthWorkoutActivityType.STEP_TRAINING,
  HealthWorkoutActivityType.TRACK_AND_FIELD,
  HealthWorkoutActivityType.WALKING,
  HealthWorkoutActivityType.WALKING_TREADMILL,
  HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE,
  HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE,
};

/// Create diary health service.
DiaryHealthService createDiaryHealthService({double? userHeightCm}) {
  return MobileDiaryHealthService(userHeightCm: userHeightCm);
}

/// Defines mobile diary health service.
class MobileDiaryHealthService implements DiaryHealthService {
  /// Creates an instance.
  MobileDiaryHealthService({Health? health, double? userHeightCm})
    : _health = health ?? Health(),
      _userHeightCm = _normalizeUserHeightCm(userHeightCm);

  final Health _health;
  final double? _userHeightCm;
  bool _isConfigured = false;

  @override
  Future<DiaryHealthDayData> loadDayData({required DateTime day}) async {
    await _ensureConfigured();

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final totalSteps =
        await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;
    final workoutPoints = await _health.getHealthDataFromTypes(
      types: _workoutQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergyPoints = await _health.getHealthDataFromTypes(
      types: _activeEnergyQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergySamples = activeEnergyPoints
        .map(_buildActiveEnergySample)
        .whereType<HealthActiveEnergySample>()
        .toList(growable: false);
    final workouts =
        workoutPoints
            .map(
              (point) => _resolveWorkout(
                point: point,
                activeEnergySamples: activeEnergySamples,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => right.start.compareTo(left.start));

    return DiaryHealthDayData(
      totalSteps: totalSteps,
      workouts: List<HealthWorkoutSession>.unmodifiable(workouts),
    );
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }

  HealthWorkoutSession _resolveWorkout({
    required HealthDataPoint point,
    required List<HealthActiveEnergySample> activeEnergySamples,
  }) {
    final workout = _backfillWorkoutSteps(
      workout: _buildWorkoutSession(point),
      point: point,
    );
    return mergeWorkoutCalories(
      workout: workout,
      activeEnergySamples: activeEnergySamples,
    );
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
  }) {
    if (!_needsWorkoutStepBackfill(point: point, workout: workout)) {
      return workout;
    }

    final estimatedSteps = _estimateStepsFromWorkoutDistance(point);
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
    if (!_stepBasedWorkoutTypes.contains(workoutValue.workoutActivityType)) {
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
    final value = point.value;
    final numericValue = switch (value) {
      NumericHealthValue(:final numericValue) => numericValue,
      _ => null,
    };
    if (numericValue == null) {
      return null;
    }
    return HealthActiveEnergySample(
      startAt: point.dateFrom.toLocal(),
      endAt: point.dateTo.toLocal(),
      numericValue: numericValue,
    );
  }

  int? _estimateStepsFromWorkoutDistance(HealthDataPoint point) {
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
      userHeightCm: _userHeightCm,
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
        (userHeightCm / _defaultCalculatorProfileHeightCm);
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

double? _normalizeUserHeightCm(double? userHeightCm) {
  if (userHeightCm == null || userHeightCm <= 0) {
    return null;
  }

  return userHeightCm.clamp(
    _minPersonalizedHeightCm,
    _maxPersonalizedHeightCm,
  );
}
