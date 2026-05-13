import 'package:flutter/widgets.dart';

/// Defines shared calorie goal calculator keys.
abstract final class CalorieGoalCalculatorSheetKeys {
  /// The step counter.
  static const stepCounter = Key('calorie_calculator_step_counter');

  /// The weight field.
  static const weightField = Key('calorie_calculator_weight_field');

  /// The height field.
  static const heightField = Key('calorie_calculator_height_field');

  /// The age field.
  static const ageField = Key('calorie_calculator_age_field');

  /// The activity level options.
  static const activityLevelOptions = Key(
    'calorie_calculator_activity_level_options',
  );

  /// The goal mode segment.
  static const goalModeSegment = Key('calorie_calculator_goal_mode_segment');

  /// The goal speed field.
  static const goalSpeedField = Key('calorie_calculator_goal_speed_field');

  /// The results card.
  static const resultsCard = Key('calorie_calculator_results_card');

  /// The goal start card.
  static const goalStartCard = Key('calorie_calculator_goal_start_card');

  /// The goal start value.
  static const goalStartValue = Key('calorie_calculator_goal_start_value');

  /// The goal start change button.
  static const goalStartChangeButton = Key(
    'calorie_calculator_goal_start_change_button',
  );

  /// The warning card.
  static const warningCard = Key('calorie_calculator_warning_card');

  /// The back button.
  static const backButton = Key('calorie_calculator_back_button');

  /// The next button.
  static const nextButton = Key('calorie_calculator_next_button');

  /// The save button.
  static const saveButton = Key('calorie_calculator_save_button');

  /// Activity level option.
  static Key activityLevelOption(String optionId) {
    return Key('calorie_calculator_activity_level_option_$optionId');
  }
}
