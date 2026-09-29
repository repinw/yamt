import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/domain/training_week_goals.dart';

void main() {
  group('resolveTrainingWeekGoals', () {
    test('rest days give back what training days get', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2000,
        trainingDays: 3,
        offsetKcal: 200,
      );

      expect(goals.trainingDayKcal, 2200);
      expect(goals.restDayKcal, 1850);
      expect(3 * goals.trainingDayKcal + 4 * goals.restDayKcal, 7 * 2000);
    });

    test('keeps every day equal without training days', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2000,
        trainingDays: 0,
        offsetKcal: 200,
      );

      expect(goals.trainingDayKcal, 2000);
      expect(goals.restDayKcal, 2000);
    });

    test('keeps every day equal when every day is a training day', () {
      final goals = resolveTrainingWeekGoals(
        baseGoalKcal: 2000,
        trainingDays: 7,
        offsetKcal: 200,
      );

      expect(goals.trainingDayKcal, 2000);
      expect(goals.restDayKcal, 2000);
    });
  });
}
