// `carryoverLimitKcalForDay`, the limit of the carryover that the week
// balance names to the user (K35 of lib/features/diary/CRITERIA.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

final DateTime _goalStart = DateTime(2026, 11, 16);

CalorieGoalSettings _goalOf(double kcal) => CalorieGoalSettings.single(
  dailyKcalGoal: kcal,
  calculatorProfile: null,
  effectiveDate: _goalStart,
);

void main() {
  test('K35: a day of the goal gets 20 % of its goal, at most 350', () {
    expect(_goalOf(1600).carryoverLimitKcalForDay(_goalStart), 320);
    expect(
      _goalOf(2200).carryoverLimitKcalForDay(addLocalDays(_goalStart, 3)),
      350,
    );
  });

  test('while the first goal is still ahead, the limit is the one of that '
      'coming goal', () {
    final settings = _goalOf(1600);

    for (final daysBefore in [1, 5]) {
      expect(
        settings.carryoverLimitKcalForDay(
          addLocalDays(_goalStart, -daysBefore),
        ),
        320,
        reason: '$daysBefore days before the goal',
      );
    }
  });
}
