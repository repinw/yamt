const _calorieGoalOnboardingKeyPrefix = 'calorie_goal_onboarding_completed';

/// The calorie goal onboarding completed value.
const calorieGoalOnboardingCompletedValue = '1';

/// Calorie goal onboarding key for user.
String calorieGoalOnboardingKeyForUser(String userId) {
  return '$_calorieGoalOnboardingKeyPrefix:$userId';
}

/// Whether [key] marks a finished onboarding of any user, which tells that
/// the app was used on this device before.
bool isCalorieGoalOnboardingKey(String key) {
  return key.startsWith('$_calorieGoalOnboardingKeyPrefix:');
}
