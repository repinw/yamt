// The mode of the week balance on the calorie settings (#911): its stored
// value (K5, K31), that no change of the settings drops it (K5), and the
// limit the mode's line names (K35).
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_learned_transitions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

final DateTime _monday = DateTime(2026, 11, 16);

CalorieGoalSettings _settings({
  double goal = 2200,
  List<int> trainingWeekdays = const [],
  double trainingDayKcalOffset = 0,
}) => CalorieGoalSettings.single(
  dailyKcalGoal: goal,
  calculatorProfile: null,
  effectiveDate: _monday,
  trainingWeekdays: trainingWeekdays,
  trainingDayKcalOffset: trainingDayKcalOffset,
);

void main() {
  group('JSON', () {
    test('K31: a stored account without the mode reads as "Anzeigen"', () {
      final json = _settings().toJson()..remove('week_balance_mode');

      expect(
        CalorieGoalSettings.fromJson(json).weekBalanceMode,
        WeekBalanceMode.show,
      );
    });

    test('K31: new settings start with "Anzeigen"', () {
      expect(_settings().weekBalanceMode, WeekBalanceMode.show);
      expect(
        const CalorieGoalSettings.empty().weekBalanceMode,
        WeekBalanceMode.show,
      );
    });

    test('K5: every mode survives the stored JSON', () {
      for (final mode in WeekBalanceMode.values) {
        final json = _settings().copyWith(weekBalanceMode: mode).toJson();

        expect(
          CalorieGoalSettings.fromJson(json).weekBalanceMode,
          mode,
          reason: mode.name,
        );
      }
    });

    test('an unknown mode fails instead of falling back', () {
      final json = _settings().toJson()..['week_balance_mode'] = 'weekly';

      expect(
        () => CalorieGoalSettings.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('K5: no change of the settings drops the mode', () {
    final day = addLocalDays(_monday, 2);
    final changes = <String, CalorieGoalSettings Function(CalorieGoalSettings)>{
      'goal change': (settings) => settings.applyGoalChange(
        changedAt: day,
        dailyKcalGoal: 2000,
        calculatorProfile: null,
      ),
      'weekly check-in goal': (settings) => settings.applyWeeklyCheckInGoal(
        completedAt: day,
        dailyKcalGoal: 2100,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: _monday,
          windowEndDate: addLocalDays(_monday, 6),
          trendWeightChangePerDay: -0.05,
          calculatedTdeeKcal: 2600,
          lowConfidence: false,
        ),
      ),
      'pending check-in cleared': (settings) =>
          settings.copyWithPendingWeeklyCheckIn(null),
      'pause day': (settings) => settings.setPauseDay(day: day, isPause: true),
      'training day toggled': (settings) => settings.toggleTrainingDay(day),
      'run training days': (settings) =>
          settings.withRunTrainingDays(day, trainingDays: {day}),
      'goal offsets': (settings) =>
          settings.withGoalOffsets({localDayKey(day): 100}),
      'skipped intake day': (settings) =>
          settings.setSkippedIntakeDay(day: day, isSkipped: true),
      'goal ended': (settings) => settings.markActiveGoalEnded(day),
      'latest goal removed': (settings) => settings
          .applyGoalChange(
            changedAt: day,
            dailyKcalGoal: 2000,
            calculatorProfile: null,
          )
          .withoutLatestGoalEntry(),
      'check-in snapshots invalidated': (settings) =>
          settings.invalidateWeeklyCheckInSnapshotsFromDay(
            day: day,
            invalidatedAt: day,
          ),
    };

    for (final MapEntry(key: name, value: change) in changes.entries) {
      for (final mode in [WeekBalanceMode.off, WeekBalanceMode.carryover]) {
        test('$name keeps "${mode.name}"', () {
          final settings = _settings().copyWith(weekBalanceMode: mode);

          expect(change(settings).weekBalanceMode, mode);
        });
      }
    }
  });

  group('K35: the limit the line names', () {
    test('20 % of the goal, at most 350 kcal', () {
      final rows = [
        (2200.0, 350.0),
        (1750.0, 350.0),
        (1600.0, 320.0),
        (1500.0, 300.0),
        (1200.0, 240.0),
      ];
      for (final (goal, limit) in rows) {
        expect(
          _settings(goal: goal).carryoverLimitKcalForDay(_monday),
          closeTo(limit, 1e-9),
          reason: '$goal',
        );
      }
    });

    test('with a weekly training plan of 1.500 and 1.750 the line names 300 '
        'on a normal day and on a training day', () {
      // Two training days of +250 in the run: a base of 1.500 + 500 / 7.
      final settings = _settings(
        goal: 1500 + 500 / 7,
        trainingWeekdays: const [DateTime.monday, DateTime.wednesday],
        trainingDayKcalOffset: 250,
      );
      final tuesday = addLocalDays(_monday, 1);

      expect(settings.goalKcalForDay(_monday), closeTo(1750, 1e-6));
      expect(settings.goalKcalForDay(tuesday), closeTo(1500, 1e-6));
      expect(settings.normalDayGoalKcalForDay(_monday), closeTo(1500, 1e-6));
      expect(settings.normalDayGoalKcalForDay(tuesday), closeTo(1500, 1e-6));
      expect(settings.carryoverLimitKcalForDay(_monday), closeTo(300, 1e-6));
      expect(settings.carryoverLimitKcalForDay(tuesday), closeTo(300, 1e-6));
    });

    test('a training day the diary added outside the plan still names the '
        'normal day', () {
      final tuesday = addLocalDays(_monday, 1);
      final settings = _settings(
        goal: 1500,
        trainingDayKcalOffset: 250,
      ).toggleTrainingDay(tuesday);

      expect(settings.goalKcalForDay(tuesday), closeTo(1750, 1e-6));
      expect(settings.normalDayGoalKcalForDay(tuesday), closeTo(1500, 1e-6));
      expect(settings.carryoverLimitKcalForDay(tuesday), closeTo(300, 1e-6));
    });
  });
}
