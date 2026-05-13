/// Quick estimate for same-day onboarding catch-up placement.
enum CalorieGoalOnboardingCatchUpEstimate {
  /// User ate less than usual so far.
  low,

  /// User ate roughly as expected so far.
  normal,

  /// User ate more than usual so far.
  high,
}

/// How a same-day onboarding start should count today's intake.
enum CalorieGoalOnboardingTodayTracking {
  /// User will track the full day accurately, so it can be learned from.
  exact,

  /// User only estimates today's intake, so it stays out of learning.
  estimate,
}
