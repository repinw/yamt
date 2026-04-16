import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
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

  /// The steps outside workouts.
  final int? stepsOutsideWorkouts;

  /// The workouts.
  final List<HealthWorkoutSession> workouts;

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

  /// Whether workout split.
  bool get hasWorkoutSplit =>
      accessState == HealthDataAccessState.ready &&
      stepsDuringWorkouts != null &&
      stepsOutsideWorkouts != null;
}

/// Build diary activity summary.
DiaryActivitySummary buildDiaryActivitySummary({
  required DateTime day,
  required DiaryHealthDayData dayData,
  int stepGoal = diaryActivityStepGoal,
}) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  final dayEnd = normalizedDay.add(const Duration(days: 1));
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
  final stepsOutsideWorkouts = dayData.totalSteps >= stepsDuringWorkouts
      ? dayData.totalSteps - stepsDuringWorkouts
      : 0;

  return DiaryActivitySummary(
    day: normalizedDay,
    stepGoal: stepGoal,
    accessState: HealthDataAccessState.ready,
    totalSteps: dayData.totalSteps,
    stepsDuringWorkouts: stepsDuringWorkouts,
    stepsOutsideWorkouts: stepsOutsideWorkouts,
    workouts: List<HealthWorkoutSession>.unmodifiable(dayWorkouts),
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
}) {
  final totalWorkoutCalories = workoutCalories.fold<int>(
    0,
    (sum, calories) => sum + (calories ?? 0),
  );
  if (stepsOutsideWorkouts == null) {
    return totalWorkoutCalories > 0 ? totalWorkoutCalories : null;
  }
  return totalWorkoutCalories +
      estimateOutsideActivityStepCalories(stepsOutsideWorkouts);
}
