import 'package:yamt/features/health/domain/health_workout_session.dart';

class DiaryHealthDayData {
  const DiaryHealthDayData({required this.totalSteps, required this.workouts});

  final int totalSteps;
  final List<HealthWorkoutSession> workouts;
}
