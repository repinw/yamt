import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/training_week_goals.dart';

void main() {
  group('resolveTrainingWeekGoals', () {
    test('a training day gets one session more than a rest day', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2100,
        trainingDays: 3,
        sessionKcal: 250,
      );

      expect(goals.trainingDayKcal - goals.restDayKcal, closeTo(250, 1e-9));
      expect(goals.restDayKcal, closeTo(2100 - 750 / 7, 1e-9));
      expect(
        3 * goals.trainingDayKcal + 4 * goals.restDayKcal,
        closeTo(7 * 2100, 1e-9),
      );
    });

    test('keeps every day equal without training days', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2000,
        trainingDays: 0,
        sessionKcal: 250,
      );

      expect(goals.trainingDayKcal, 2000);
      expect(goals.restDayKcal, 2000);
    });

    test('keeps every day equal when every day is a training day', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2000,
        trainingDays: 7,
        sessionKcal: 250,
      );

      expect(goals.trainingDayKcal, 2000);
      expect(goals.restDayKcal, 2000);
    });
  });

  group('trainingKcalPerDay', () {
    test('spreads the weekly sessions over seven days', () {
      expect(
        trainingKcalPerDay(trainingDays: 3, sessionKcal: 250),
        closeTo(750 / 7, 1e-9),
      );
    });

    test('adds nothing without sessions or without session kcal', () {
      expect(trainingKcalPerDay(trainingDays: 0, sessionKcal: 250), 0);
      expect(trainingKcalPerDay(trainingDays: 3, sessionKcal: 0), 0);
    });
  });
}
