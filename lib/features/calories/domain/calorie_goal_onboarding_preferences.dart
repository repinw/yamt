const _calorieGoalOnboardingKeyPrefix = 'calorie_goal_onboarding_completed';
const calorieGoalOnboardingCompletedValue = '1';

String calorieGoalOnboardingKeyForUser(String userId) {
  return '$_calorieGoalOnboardingKeyPrefix:$userId';
}
