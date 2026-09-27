import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';

// 2026-09-01 is a Tuesday; the runs start on it and every seven days after.
final _goalStart = DateTime(2026, 9);
final _now = DateTime(2026, 9, 10, 9);

CalorieGoalSettings _settings() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
      trainingWeekdays: [DateTime.monday, DateTime.wednesday],
      trainingDayKcalOffset: 200,
    ),
    effectiveDate: _goalStart,
  );
}

void main() {
  test('the plan lists the days of the run that contains the day', () {
    final plan = _settings()
        .setPauseDay(day: DateTime(2026, 9, 12), isPause: true)
        .runTrainingPlan(_now);

    expect(plan.days.first, DateTime(2026, 9, 8));
    expect(plan.lastDay, DateTime(2026, 9, 14));
    expect(plan.trainingDays, {DateTime(2026, 9, 9), DateTime(2026, 9, 14)});
    expect(plan.pauseDays, {DateTime(2026, 9, 12)});
  });

  test('new training days only change the days of the run', () {
    final settings = _settings().setPauseDay(
      day: DateTime(2026, 9, 12),
      isPause: true,
    );

    final next = settings.withRunTrainingDays(
      _now,
      trainingDays: {DateTime(2026, 9, 10), DateTime(2026, 9, 14)},
    );

    expect(next.isTrainingDay(DateTime(2026, 9, 9)), isFalse);
    expect(next.isTrainingDay(DateTime(2026, 9, 10)), isTrue);
    expect(next.isTrainingDay(DateTime(2026, 9, 14)), isTrue);
    expect(next.trainingDayOverrides, {'2026-9-9': false, '2026-9-10': true});
    // The next run follows the weekly schedule again.
    expect(next.isTrainingDay(DateTime(2026, 9, 16)), isTrue);
    expect(next.isTrainingDay(DateTime(2026, 9, 17)), isFalse);
    expect(next.isPauseDay(DateTime(2026, 9, 12)), isTrue);
  });

  test('picking the schedule again removes the overrides', () {
    final changed = _settings().withRunTrainingDays(
      _now,
      trainingDays: {DateTime(2026, 9, 10)},
    );

    final restored = changed.withRunTrainingDays(
      _now,
      trainingDays: {DateTime(2026, 9, 9), DateTime(2026, 9, 14)},
    );

    expect(restored.trainingDayOverrides, isEmpty);
  });

  test('an extra training day moves calories only within its run', () {
    final settings = _settings();
    final next = settings.withRunTrainingDays(
      _now,
      trainingDays: {
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 14),
      },
    );

    List<DateTime> runDays(DateTime start) => [
      for (var offset = 0; offset < 7; offset++)
        DateTime(start.year, start.month, start.day + offset),
    ];
    double sumOf(CalorieGoalSettings settings, DateTime start) =>
        runDays(start)
            .fold(0, (sum, day) => sum + settings.goalKcalForDay(day));

    // Two training days: 2.000 + 200, rest days 2.000 − 2 × 200 / 5.
    expect(settings.goalKcalForDay(DateTime(2026, 9, 10)), 1920);
    // Three training days: rest days 2.000 − 3 × 200 / 4.
    expect(next.goalKcalForDay(DateTime(2026, 9, 10)), 2200);
    expect(next.goalKcalForDay(DateTime(2026, 9, 8)), 1850);
    expect(sumOf(next, DateTime(2026, 9, 8)), 14000);
    expect(sumOf(settings, DateTime(2026, 9, 8)), 14000);
    // The run before keeps its goals.
    for (final day in runDays(_goalStart)) {
      expect(next.goalKcalForDay(day), settings.goalKcalForDay(day));
    }
  });
}
