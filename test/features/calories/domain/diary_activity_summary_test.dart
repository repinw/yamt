import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
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

  test(
    'buildDiaryActivitySummary separates unassigned active energy steps',
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
          ],
          unassignedActiveEnergySegments: [
            HealthEnergySegment(
              id: 'energy-1',
              start: day.add(const Duration(hours: 14)),
              endExclusive: day.add(const Duration(hours: 14, minutes: 30)),
              durationMinutes: 30,
              sourceName: 'health-connect',
              totalCalories: 160,
              totalSteps: 900,
            ),
          ],
        ),
      );
      final burnedCalories = calculateDiaryBurnedCalories(
        stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
        workoutCalories: summary.workouts.map(
          (workout) => workout.totalCalories,
        ),
        unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
      );

      expect(summary.stepsDuringWorkouts, 3100);
      expect(summary.stepsDuringUnassignedActiveEnergy, 900);
      expect(summary.stepsOutsideWorkouts, 3200);
      expect(burnedCalories, 664);
    },
  );

  test(
    'buildDiaryActivitySummary filters unassigned energy to selected day',
    () {
      final day = DateTime(2026, 4, 15);
      final summary = buildDiaryActivitySummary(
        day: day,
        dayData: DiaryHealthDayData(
          totalSteps: 5000,
          workouts: const <HealthWorkoutSession>[],
          unassignedActiveEnergySegments: [
            HealthEnergySegment(
              id: 'outside-day',
              start: day.subtract(const Duration(hours: 2)),
              endExclusive: day.subtract(const Duration(hours: 1)),
              durationMinutes: 60,
              sourceName: 'health-connect',
              totalCalories: 200,
              totalSteps: 1000,
            ),
            HealthEnergySegment(
              id: 'inside-day',
              start: day.add(const Duration(hours: 12)),
              endExclusive: day.add(const Duration(hours: 12, minutes: 30)),
              durationMinutes: 30,
              sourceName: 'health-connect',
              totalCalories: 120,
              totalSteps: 600,
            ),
          ],
        ),
      );

      expect(summary.unassignedActiveEnergySegments, hasLength(1));
      expect(summary.unassignedActiveEnergySegments.single.id, 'inside-day');
      expect(summary.stepsDuringUnassignedActiveEnergy, 600);
      expect(summary.stepsOutsideWorkouts, 4400);
    },
  );

  test(
    'calculateDiaryBurnedCalories ignores unassigned energy without steps',
    () {
      final day = DateTime(2026, 4, 15);
      final burnedCalories = calculateDiaryBurnedCalories(
        stepsOutsideWorkouts: null,
        workoutCalories: const <int?>[null],
        unassignedActiveEnergySegments: [
          HealthEnergySegment(
            id: 'energy-1',
            start: day.add(const Duration(hours: 12)),
            endExclusive: day.add(const Duration(hours: 13)),
            durationMinutes: 60,
            sourceName: 'health-connect',
            totalCalories: 120,
            totalSteps: null,
          ),
        ],
      );

      expect(burnedCalories, isNull);
    },
  );

  group('estimateUnassignedActiveEnergyCalories', () {
    test('returns zero when segment steps are null', () {
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 120, totalSteps: null),
        ),
        0,
      );
    });

    test('returns zero when segment steps are not positive', () {
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 120, totalSteps: 0),
        ),
        0,
      );
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 120, totalSteps: -1),
        ),
        0,
      );
    });

    test('returns zero when segment calories are not positive', () {
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 0, totalSteps: 1000),
        ),
        0,
      );
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: -10, totalSteps: 1000),
        ),
        0,
      );
    });

    test('keeps calories below estimated step calories', () {
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 30, totalSteps: 1000),
        ),
        30,
      );
    });

    test('caps calories above estimated step calories', () {
      expect(
        estimateUnassignedActiveEnergyCalories(
          _energySegment(totalCalories: 120, totalSteps: 1000),
        ),
        40,
      );
    });
  });
}

HealthEnergySegment _energySegment({
  required int totalCalories,
  required int? totalSteps,
}) {
  final start = DateTime(2026, 4, 15, 12);
  return HealthEnergySegment(
    id: 'energy',
    start: start,
    endExclusive: start.add(const Duration(minutes: 30)),
    durationMinutes: 30,
    sourceName: 'health-connect',
    totalCalories: totalCalories,
    totalSteps: totalSteps,
  );
}
