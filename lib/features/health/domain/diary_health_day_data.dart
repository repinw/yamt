import 'package:yamt/features/health/domain/health_workout_session.dart';

/// Defines diary health day data.
class DiaryHealthDayData {
  /// The diary health day data.
  const DiaryHealthDayData({required this.totalSteps, required this.workouts});

  /// The total steps.
  final int totalSteps;

  /// The workouts.
  final List<HealthWorkoutSession> workouts;
}
