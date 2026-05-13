import 'package:flutter/widgets.dart';

/// Defines stable keys for calorie-goal onboarding widgets.
abstract final class CalorieGoalOnboardingKeys {
  /// The goal start card.
  static const goalStartCard = Key('calorie_calculator_goal_start_card');

  /// The goal start value.
  static const goalStartValue = Key('calorie_calculator_goal_start_value');

  /// The goal start change button.
  static const goalStartChangeButton = Key(
    'calorie_calculator_goal_start_change_button',
  );

  /// The onboarding start-now option.
  static const goalStartNowOption = Key(
    'calorie_calculator_goal_start_now_option',
  );

  /// The onboarding start-later option.
  static const goalStartLaterOption = Key(
    'calorie_calculator_goal_start_later_option',
  );

  /// The onboarding exact today tracking option.
  static const todayTrackingExactOption = Key(
    'calorie_calculator_today_tracking_exact_option',
  );

  /// The onboarding estimated today tracking option.
  static const todayTrackingEstimateOption = Key(
    'calorie_calculator_today_tracking_estimate_option',
  );

  /// The onboarding catch-up low option.
  static const catchUpLowOption = Key(
    'calorie_calculator_catch_up_low_option',
  );

  /// The onboarding catch-up normal option.
  static const catchUpNormalOption = Key(
    'calorie_calculator_catch_up_normal_option',
  );

  /// The onboarding catch-up high option.
  static const catchUpHighOption = Key(
    'calorie_calculator_catch_up_high_option',
  );
}
