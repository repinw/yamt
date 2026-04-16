const _calorieGoalOnboardingKeyPrefix = 'calorie_goal_onboarding_completed';

/// The calorie goal onboarding completed value.
const calorieGoalOnboardingCompletedValue = '1';

/// Calorie goal onboarding key for user.
String calorieGoalOnboardingKeyForUser(String userId) {
  return '$_calorieGoalOnboardingKeyPrefix:$userId';
}
