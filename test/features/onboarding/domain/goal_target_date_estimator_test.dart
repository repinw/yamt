import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/domain/goal_target_date_estimator.dart';

void main() {
  final today = DateTime(2026, 9, 17);

  test('estimates the day a weight loss goal is reached', () {
    final reachedOn = estimateGoalReachedDate(
      currentWeightKg: 80,
      targetWeightKg: 76,
      goalSpeedKgPerWeek: 0.5,
      today: today,
    );

    expect(reachedOn, DateTime(2026, 9, 17 + 56));
  });

  test('estimates the day a weight gain goal is reached', () {
    final reachedOn = estimateGoalReachedDate(
      currentWeightKg: 70,
      targetWeightKg: 73,
      goalSpeedKgPerWeek: 0.25,
      today: today,
    );

    expect(reachedOn, DateTime(2026, 9, 17 + 84));
  });

  test('rounds a partial day up to the next full day', () {
    final reachedOn = estimateGoalReachedDate(
      currentWeightKg: 80,
      targetWeightKg: 79.9,
      goalSpeedKgPerWeek: 0.5,
      today: today,
    );

    expect(reachedOn, DateTime(2026, 9, 19));
  });

  test('returns null without a pace', () {
    expect(
      estimateGoalReachedDate(
        currentWeightKg: 80,
        targetWeightKg: 75,
        goalSpeedKgPerWeek: 0,
        today: today,
      ),
      isNull,
    );
  });

  test('returns null when the target is already reached', () {
    expect(
      estimateGoalReachedDate(
        currentWeightKg: 80,
        targetWeightKg: 80,
        goalSpeedKgPerWeek: 0.5,
        today: today,
      ),
      isNull,
    );
  });
}
