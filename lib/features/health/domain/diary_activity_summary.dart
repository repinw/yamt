import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

/// The diary activity step goal.
const int diaryActivityStepGoal = 10000;

// Rough fallback: about 40 kcal per 1,000 casual walking steps.
// Keep simple until estimate can use profile data like body weight.
const double _estimatedCaloriesPerOutsideStep = 0.04;

/// Defines diary activity summary.
class DiaryActivitySummary {
  /// The diary activity summary.
  const DiaryActivitySummary({
    required this.day,
    required this.stepGoal,
    required this.accessState,
    required this.totalSteps,
    required this.stepsDuringWorkouts,
    required this.stepsOutsideWorkouts,
    required this.workouts,
    this.stepsDuringUnassignedActiveEnergy = 0,
    this.unassignedActiveEnergySegments = const <HealthEnergySegment>[],
  });

  /// Creates a [DiaryActivitySummary] for locked.
  factory DiaryActivitySummary.locked({
    required DateTime day,
    required HealthDataAccessState accessState,
    int stepGoal = diaryActivityStepGoal,
  }) {
    return DiaryActivitySummary(
      day: DateTime(day.year, day.month, day.day),
      stepGoal: stepGoal,
      accessState: accessState,
      totalSteps: null,
      stepsDuringWorkouts: null,
      stepsOutsideWorkouts: null,
      workouts: const <HealthWorkoutSession>[],
    );
  }

  /// The day.
  final DateTime day;

  /// The step goal.
  final int stepGoal;

  /// The access state.
  final HealthDataAccessState accessState;

  /// The total steps.
  final int? totalSteps;

  /// The steps during workouts.
  final int? stepsDuringWorkouts;

  /// The steps during unassigned active energy that counts as activity.
  final int stepsDuringUnassignedActiveEnergy;

  /// The steps outside workouts.
  final int? stepsOutsideWorkouts;

  /// The workouts.
  final List<HealthWorkoutSession> workouts;

  /// The active energy segments that count without a matching workout.
  final List<HealthEnergySegment> unassignedActiveEnergySegments;

  /// The workout count.
  int get workoutCount => workouts.length;

  /// The progress.
  double get progress {
    final totalSteps = this.totalSteps;
    if (totalSteps == null || stepGoal <= 0) {
      return 0;
    }
    final rawProgress = totalSteps / stepGoal;
    if (rawProgress <= 0) {
      return 0;
    }
    if (rawProgress >= 1) {
      return 1;
    }
    return rawProgress;
  }
}

/// Build diary activity summary.
DiaryActivitySummary buildDiaryActivitySummary({
  required DateTime day,
  required DiaryHealthDayData dayData,
  int stepGoal = diaryActivityStepGoal,
}) {
  final normalizedDay = normalizeLocalDay(day);
  final dayEnd = nextLocalDay(normalizedDay);
  final dayWorkouts = dayData.workouts
      .where(
        (workout) =>
            workout.endExclusive.isAfter(normalizedDay) &&
            workout.start.isBefore(dayEnd),
      )
      .toList(growable: false);
  final stepsDuringWorkouts = dayWorkouts.fold<int>(
    0,
    (sum, workout) => sum + (workout.totalSteps ?? 0),
  );
  final dayUnassignedActiveEnergySegments = dayData
      .unassignedActiveEnergySegments
      .where(
        (segment) =>
            segment.endExclusive.isAfter(normalizedDay) &&
            segment.start.isBefore(dayEnd),
      )
      .toList(growable: false);
  final stepsDuringUnassignedActiveEnergy = dayUnassignedActiveEnergySegments
      .fold<int>(
        0,
        (sum, segment) => sum + (segment.totalSteps ?? 0),
      );
  final accountedSteps =
      stepsDuringWorkouts + stepsDuringUnassignedActiveEnergy;
  final stepsOutsideWorkouts = dayData.totalSteps >= accountedSteps
      ? dayData.totalSteps - accountedSteps
      : 0;

  return DiaryActivitySummary(
    day: normalizedDay,
    stepGoal: stepGoal,
    accessState: HealthDataAccessState.ready,
    totalSteps: dayData.totalSteps,
    stepsDuringWorkouts: stepsDuringWorkouts,
    stepsDuringUnassignedActiveEnergy: stepsDuringUnassignedActiveEnergy,
    stepsOutsideWorkouts: stepsOutsideWorkouts,
    workouts: List<HealthWorkoutSession>.unmodifiable(dayWorkouts),
    unassignedActiveEnergySegments: List<HealthEnergySegment>.unmodifiable(
      dayUnassignedActiveEnergySegments,
    ),
  );
}

/// Estimate outside activity step calories.
int estimateOutsideActivityStepCalories(int stepsOutsideWorkouts) {
  if (stepsOutsideWorkouts <= 0) {
    return 0;
  }
  return (stepsOutsideWorkouts * _estimatedCaloriesPerOutsideStep).round();
}

/// Calculate diary burned calories.
int? calculateDiaryBurnedCalories({
  required int? stepsOutsideWorkouts,
  required Iterable<int?> workoutCalories,
  Iterable<HealthEnergySegment> unassignedActiveEnergySegments =
      const <HealthEnergySegment>[],
}) {
  final totalWorkoutCalories = workoutCalories.fold<int>(
    0,
    (sum, calories) => sum + (calories ?? 0),
  );
  final totalUnassignedActiveEnergyCalories = unassignedActiveEnergySegments
      .fold<int>(
        0,
        (sum, segment) => sum + estimateUnassignedActiveEnergyCalories(segment),
      );
  final totalTrackedCalories =
      totalWorkoutCalories + totalUnassignedActiveEnergyCalories;
  if (stepsOutsideWorkouts == null) {
    return totalTrackedCalories > 0 ? totalTrackedCalories : null;
  }
  return totalTrackedCalories +
      estimateOutsideActivityStepCalories(stepsOutsideWorkouts);
}

/// Estimate credited calories for active energy without a matching workout.
int estimateUnassignedActiveEnergyCalories(HealthEnergySegment segment) {
  final totalSteps = segment.totalSteps;
  if (totalSteps == null || totalSteps <= 0) {
    return 0;
  }

  final stepCalories = estimateOutsideActivityStepCalories(totalSteps);
  if (stepCalories <= 0 || segment.totalCalories <= 0) {
    return 0;
  }
  return segment.totalCalories < stepCalories
      ? segment.totalCalories
      : stepCalories;
}
