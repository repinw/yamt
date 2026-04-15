import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

void main() {
  test('mergeWorkoutCalories uses overlapped active energy samples', () {
    final workout = HealthWorkoutSession(
      id: 'walk-1',
      start: DateTime(2026, 4, 15, 7, 0),
      endExclusive: DateTime(2026, 4, 15, 8, 0),
      durationMinutes: 60,
      activityLabel: 'Walking',
      sourceName: 'Health Connect',
      totalCalories: 90,
      totalSteps: 3200,
    );

    final merged = mergeWorkoutCalories(
      workout: workout,
      activeEnergySamples: [
        HealthActiveEnergySample(
          startAt: DateTime(2026, 4, 15, 7, 0),
          endAt: DateTime(2026, 4, 15, 7, 30),
          numericValue: 120,
        ),
        HealthActiveEnergySample(
          startAt: DateTime(2026, 4, 15, 7, 30),
          endAt: DateTime(2026, 4, 15, 8, 30),
          numericValue: 120,
        ),
      ],
    );

    expect(merged.totalCalories, 180);
  });

  test(
    'mergeWorkoutCalories falls back to workout calories without overlap',
    () {
      final workout = HealthWorkoutSession(
        id: 'run-1',
        start: DateTime(2026, 4, 15, 7, 0),
        endExclusive: DateTime(2026, 4, 15, 8, 0),
        durationMinutes: 60,
        activityLabel: 'Running',
        sourceName: 'Health Connect',
        totalCalories: 200,
        totalSteps: 4000,
      );

      final merged = mergeWorkoutCalories(
        workout: workout,
        activeEnergySamples: [
          HealthActiveEnergySample(
            startAt: DateTime(2026, 4, 15, 9, 0),
            endAt: DateTime(2026, 4, 15, 10, 0),
            numericValue: 150,
          ),
        ],
      );

      expect(merged.totalCalories, 200);
    },
  );
}
