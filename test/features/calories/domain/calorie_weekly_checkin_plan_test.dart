import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

CalorieWeeklyCheckInPlan _plan({
  CalorieWeeklyCheckInMeasurement? measurement = (
    tdeeKcal: 2240,
    goalKcal: 1690,
    averageIntakeKcal: 1640,
  ),
}) {
  final days = [for (var day = 1; day <= 7; day++) DateTime(2026, 9, day)];
  return CalorieWeeklyCheckInPlan(
    reviewedRunNumber: 4,
    reviewedDays: (start: DateTime(2026, 8, 25), end: DateTime(2026, 8, 31)),
    previousTrainingDayCount: 3,
    nextRunDays: days,
    suggestedTrainingDays: {days[0], days[2], days[4]},
    pauseDays: const {},
    sessionKcal: 350,
    previousTdeeKcal: 2164,
    previousGoalKcal: 1614,
    measurement: measurement,
    progress: null,
    profile: null,
    macroSettings: const MacroGoalSettings(),
    previousMacroWeightKg: 79.6,
    newMacroWeightKg: 78.9,
    isLosingWeight: true,
  );
}

void main() {
  test('the measured TDEE sets the goal and splits it over the week', () {
    final targets = _plan().targetsFor(useMeasured: true, trainingDays: 3);

    expect(targets.isMeasured, isTrue);
    expect(targets.goalKcal, 1690);
    expect(targets.goalChangeKcal, 76);
    // 350 kcal a session: training days get 4/7 of it more, rest days 3/7
    // less, so the week stays at 7 × 1690.
    expect(targets.trainingDayKcal, 1890);
    expect(targets.restDayKcal, 1540);
    // Without a calculator profile, the macros count against 80 kg.
    expect(targets.macroWeightKg, 80);
  });

  test('keeping the previous TDEE keeps the previous goal', () {
    final targets = _plan().targetsFor(useMeasured: false, trainingDays: 0);

    expect(targets.isMeasured, isFalse);
    expect(targets.goalKcal, 1614);
    expect(targets.goalChangeKcal, 0);
    expect(targets.trainingDayKcal, 1614);
    expect(targets.restDayKcal, 1614);
  });

  test('without a measurement the previous goal applies', () {
    final targets = _plan(measurement: null)
        .targetsFor(useMeasured: true, trainingDays: 3);

    expect(targets.isMeasured, isFalse);
    expect(targets.goalKcal, 1614);
  });

  test('the extra kcal of the measured goal go to carbs', () {
    final targets = _plan().targetsFor(useMeasured: true, trainingDays: 3);

    expect(targets.macros.carbs, greaterThan(targets.previousMacros.carbs));
    expect(targets.macros.fat, targets.previousMacros.fat);
  });
}
