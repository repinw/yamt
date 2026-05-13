import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';

void main() {
  group('calorie goal onboarding preferences', () {
    test('builds a stable user-specific completion key', () {
      expect(
        calorieGoalOnboardingKeyForUser('user-123'),
        'calorie_goal_onboarding_completed:user-123',
      );
    });

    test('uses a compact completion marker value', () {
      expect(calorieGoalOnboardingCompletedValue, '1');
    });
  });
}
