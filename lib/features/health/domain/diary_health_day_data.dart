import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

/// Defines diary health day data.
class DiaryHealthDayData {
  /// The diary health day data.
  const DiaryHealthDayData({
    required this.totalSteps,
    required this.workouts,
    this.unassignedActiveEnergySegments = const <HealthEnergySegment>[],
  });

  /// The total steps.
  final int totalSteps;

  /// The workouts.
  final List<HealthWorkoutSession> workouts;

  /// Active energy not tied to a workout, filtered to likely activity.
  final List<HealthEnergySegment> unassignedActiveEnergySegments;
}
