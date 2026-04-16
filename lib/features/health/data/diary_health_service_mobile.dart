import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

const _logName = 'DiaryHealthService';

const _workoutQueryTypes = <HealthDataType>[HealthDataType.WORKOUT];
const _activeEnergyQueryTypes = <HealthDataType>[
  HealthDataType.ACTIVE_ENERGY_BURNED,
];

/// Create diary health service.
DiaryHealthService createDiaryHealthService() {
  return MobileDiaryHealthService();
}

/// Defines mobile diary health service.
class MobileDiaryHealthService implements DiaryHealthService {
  /// Creates an instance.
  MobileDiaryHealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
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
              (point) => mergeWorkoutCalories(
                workout: _buildWorkoutSession(point),
                activeEnergySamples: activeEnergySamples,
              ),
            )
            .toList()
          ..sort((left, right) => right.start.compareTo(left.start));

    log(
      'Read diary health data. '
      'day=${dayStart.toIso8601String()} '
      'steps=$totalSteps '
      'active_energy_samples=${activeEnergySamples.length} '
      'workouts=${workouts.length}',
      name: _logName,
    );

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

  HealthWorkoutSession _buildWorkoutSession(HealthDataPoint point) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    return HealthWorkoutSession(
      id: point.uuid.isNotEmpty
          ? point.uuid
          : '${point.sourceId}:${point.dateFrom.toUtc().millisecondsSinceEpoch}',
      start: point.dateFrom.toLocal(),
      endExclusive: point.dateTo.toLocal(),
      durationMinutes: point.dateTo.difference(point.dateFrom).inSeconds / 60,
      activityLabel: workoutValue == null
          ? null
          : _formatWorkoutActivityLabel(workoutValue.workoutActivityType),
      sourceName: point.sourceName.isEmpty ? null : point.sourceName,
      totalCalories: workoutValue?.totalEnergyBurned,
      totalSteps: workoutValue?.totalSteps,
    );
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
