import 'package:flutter/widgets.dart';

/// Defines stable keys for calorie-goal onboarding widgets.
abstract final class CalorieGoalOnboardingKeys {
  /// The action that starts the setup from the welcome page.
  static const introStartAction = Key('calorie_intro_start_action');

  /// The action that opens the authentication page.
  static const introLoginAction = Key('calorie_intro_login_action');

  /// The birthday day wheel.
  static const introBirthDayWheel = Key('calorie_intro_birth_day_wheel');

  /// The birthday month wheel.
  static const introBirthMonthWheel = Key('calorie_intro_birth_month_wheel');

  /// The birthday year wheel.
  static const introBirthYearWheel = Key('calorie_intro_birth_year_wheel');

  /// The height wheel.
  static const introHeightWheel = Key('calorie_intro_height_wheel');

  /// The current-weight wheel.
  static const introWeightWheel = Key('calorie_intro_weight_wheel');

  /// The target-weight wheel.
  static const introTargetWeightWheel = Key(
    'calorie_intro_target_weight_wheel',
  );

  /// The weight-change pace wheel.
  static const introPaceWheel = Key('calorie_intro_pace_wheel');

  /// The estimated day the target weight is reached.
  static const introTargetDateEstimate = Key(
    'calorie_intro_target_date_estimate',
  );

  /// The action that saves the goal and leaves onboarding.
  static const introFinishAction = Key('calorie_intro_finish_action');

  /// The shared next action of the intro controls.
  static const introNextAction = Key('calorie_intro_next_action');

  /// The shared back action of the intro controls.
  static const introBackAction = Key('calorie_intro_back_action');
}
