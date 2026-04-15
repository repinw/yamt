import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

void main() {
  test(
    'buildDiaryActivitySummary uses selected day steps and workout split',
    () {
      final day = DateTime(2026, 4, 15);
      final summary = buildDiaryActivitySummary(
        day: day,
        dayData: DiaryHealthDayData(
          totalSteps: 7200,
          workouts: [
            HealthWorkoutSession(
              id: 'run-1',
              start: day.add(const Duration(hours: 7)),
              endExclusive: day.add(const Duration(hours: 8)),
              durationMinutes: 60,
              activityLabel: 'Running',
              sourceName: 'health-connect',
              totalCalories: 500,
              totalSteps: 3100,
            ),
            HealthWorkoutSession(
              id: 'walk-1',
              start: day.add(const Duration(hours: 18)),
              endExclusive: day.add(const Duration(hours: 18, minutes: 30)),
              durationMinutes: 30,
              activityLabel: 'Walking',
              sourceName: 'health-connect',
              totalCalories: 120,
              totalSteps: 900,
            ),
          ],
        ),
      );

      expect(summary.accessState, HealthDataAccessState.ready);
      expect(summary.totalSteps, 7200);
      expect(summary.stepsDuringWorkouts, 4000);
      expect(summary.stepsOutsideWorkouts, 3200);
      expect(summary.workoutCount, 2);
      expect(summary.progress, closeTo(0.72, 0.0001));
    },
  );

  test('buildDiaryActivitySummary clamps outside steps to zero', () {
    final day = DateTime(2026, 4, 15);
    final summary = buildDiaryActivitySummary(
      day: day,
      dayData: DiaryHealthDayData(
        totalSteps: 1000,
        workouts: [
          HealthWorkoutSession(
            id: 'run-1',
            start: day.add(const Duration(hours: 7)),
            endExclusive: day.add(const Duration(hours: 8)),
            durationMinutes: 60,
            activityLabel: 'Running',
            sourceName: 'health-connect',
            totalCalories: 500,
            totalSteps: 1500,
          ),
        ],
      ),
    );

    expect(summary.stepsDuringWorkouts, 1500);
    expect(summary.stepsOutsideWorkouts, 0);
  });

  test('calculateDiaryBurnedCalories combines workout and outside steps', () {
    final burnedCalories = calculateDiaryBurnedCalories(
      stepsOutsideWorkouts: 3200,
      workoutCalories: const <int?>[500, 120],
    );

    expect(burnedCalories, 748);
  });
}
