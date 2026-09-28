import 'package:flutter/widgets.dart';

/// Defines calorie goal start dialog keys.
abstract final class CalorieGoalStartDialogKeys {
  /// The change date button.
  static const changeDateButton = Key('calorie_goal_start_change_date_button');

  /// The save button.
  static const saveButton = Key('calorie_goal_start_save_button');
}

/// Defines same-day goal start food tracking dialog keys.
abstract final class CalorieGoalStartFoodTrackingDialogKeys {
  /// The no/start fresh button.
  static const noButton = Key('calorie_goal_start_food_tracking_no');

  /// The yes/count today button.
  static const yesButton = Key('calorie_goal_start_food_tracking_yes');
}

/// Defines calorie learned tdee sheet keys.
abstract final class CalorieLearnedTdeeSheetKeys {
  /// The sheet.
  static const sheet = Key('calorie_learned_tdee_sheet');

  /// The save button.
  static const saveButton = Key('calorie_learned_tdee_save_button');

  /// The full reset button.
  static const fullResetButton = Key('calorie_learned_tdee_full_reset_button');
}

/// Defines calorie entry editor keys.
abstract final class CalorieEntryEditorKeys {
  /// The name field.
  static const nameField = Key('calorie_entry_name_field');

  /// The amount field.
  static const amountField = Key('calorie_entry_amount_field');

  /// The unit field.
  static const unitField = Key('calorie_entry_unit_field');

  /// The per100 kcal field.
  static const per100KcalField = Key('calorie_entry_per100_kcal_field');

  /// The per100 protein field.
  static const per100ProteinField = Key('calorie_entry_per100_protein_field');

  /// The per100 carbs field.
  static const per100CarbsField = Key('calorie_entry_per100_carbs_field');

  /// The per100 fat field.
  static const per100FatField = Key('calorie_entry_per100_fat_field');

  /// The save button.
  static const saveButton = Key('calorie_entry_save_button');
}
