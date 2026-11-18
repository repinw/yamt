import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';

/// Monday 2026-11-16, the first day of the old run.
final DateTime _monday = DateTime(2026, 11, 16);

DateTime _day(int index) => addLocalDays(_monday, index);

const _profile = CalorieCalculatorProfile(
  sex: CalorieCalculatorSex.male,
  weightKg: 80,
  heightCm: 180,
  ageYears: 30,
  activityLevel: 1.2,
  goalMode: CalorieGoalMode.lose,
  goalSpeedKgPerWeek: 0.5,
  trainingDayKcalOffset: 350,
  trainingWeekdays: [DateTime.monday, DateTime.wednesday],
);

/// K48's training example: the old goal from Monday averages 2.200 with 350
/// kcal per session and trains on Monday and Wednesday.
CalorieGoalSettings _oldGoal() => CalorieGoalSettings.single(
  dailyKcalGoal: 2200,
  calculatorProfile: _profile,
  effectiveDate: _monday,
  countingStartDate: _monday,
  trainingWeekdays: _profile.trainingWeekdays,
  trainingDayKcalOffset: 350,
);

/// The new goal set on Thursday at 10:00 with the same average and session
/// that trains on Thursday, Friday and Saturday and counts from [from], as
/// the app's goal save stores it (effective on Thursday).
CalorieGoalSettings _withNewGoal({required DateTime from}) =>
    _oldGoal().applyGoalChange(
      changedAt: DateTime(2026, 11, 19, 10),
      dailyKcalGoal: 2200,
      calculatorProfile: _profile.copyWith(
        trainingWeekdays: [
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
        ],
      ),
      countingStartDate: from,
      source: CalorieGoalSource.calculator,
      replaceFutureHistory: true,
    );

/// Goals of Monday, Tuesday and Wednesday.
List<double> _oldRunGoals(CalorieGoalSettings settings) => [
  for (var index = 0; index < 3; index += 1)
    settings.goalKcalForDay(_day(index)),
];

void main() {
  group('goals of a run cut short by a new goal (K48)', () {
    test('K48: without a new goal, Monday to Wednesday have 2.450, 2.100 and '
        '2.450', () {
      expect(_oldRunGoals(_oldGoal()), [2450, 2100, 2450]);
    });

    test('K48: a new goal from Thursday with other training days leaves '
        'them at 2.450, 2.100 and 2.450, not 2.300, 1.950 and 2.300', () {
      final settings = _withNewGoal(from: _day(3));

      expect(_oldRunGoals(settings), [2450, 2100, 2450]);
    });

    test('K48, K49: the same when the new goal counts from Saturday: the old '
        'run still ends on Wednesday', () {
      final settings = _withNewGoal(from: _day(5));

      expect(_oldRunGoals(settings), [2450, 2100, 2450]);
    });
  });

  group('planned training days of a run cut short by a new goal (K48)', () {
    test('K48: Tuesday planned as training in the old run splits it with '
        'three sessions after the new goal too: 2.400 each', () {
      final planned = _oldGoal().withRunTrainingDays(
        _monday,
        trainingDays: {_day(0), _day(1), _day(2)},
      );
      expect(planned.trainingDayOverrides, {localDayKey(_day(1)): true});
      // Three sessions: 2.200 + 4 × 350 / 7 on each training day.
      expect(_oldRunGoals(planned), [2400, 2400, 2400]);

      final settings = planned.applyGoalChange(
        changedAt: DateTime(2026, 11, 19, 10),
        dailyKcalGoal: 2200,
        calculatorProfile: _profile.copyWith(
          trainingWeekdays: [
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          ],
        ),
        countingStartDate: _day(3),
        source: CalorieGoalSource.calculator,
        replaceFutureHistory: true,
      );

      expect(_oldRunGoals(settings), [2400, 2400, 2400]);
    });

    test('K48: Monday planned as a rest day in the old run leaves one '
        'session after the new goal too: 2.150, 2.150, 2.500', () {
      final planned = _oldGoal().withRunTrainingDays(
        _monday,
        trainingDays: {_day(2)},
      );
      final settings = planned.applyGoalChange(
        changedAt: DateTime(2026, 11, 19, 10),
        dailyKcalGoal: 2200,
        calculatorProfile: _profile.copyWith(
          trainingWeekdays: [
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
          ],
        ),
        countingStartDate: _day(3),
        source: CalorieGoalSource.calculator,
        replaceFutureHistory: true,
      );

      // One session: rest days 2.200 − 350 / 7, the training day 6 × 350 / 7
      // above the average.
      expect(_oldRunGoals(settings), [2150, 2150, 2500]);
    });

    test('K48: a training day planned in the new run does not change the '
        'goals of the old run', () {
      // The new run from Thursday plans Sunday as a fourth training day;
      // Sunday lies within seven days of the old run's Monday.
      final settings = _withNewGoal(from: _day(3)).withRunTrainingDays(
        _day(3),
        trainingDays: {_day(3), _day(4), _day(5), _day(6)},
      );
      expect(settings.isTrainingDay(_day(6)), isTrue);

      expect(_oldRunGoals(settings), [2450, 2100, 2450]);
    });
  });
}
