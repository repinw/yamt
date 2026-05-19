import 'package:flutter/widgets.dart';

/// Defines shared calorie feature keys.
abstract final class CaloriesPageKeys {
  /// Entry image.
  static Key entryImage(String entryId) {
    return Key('calories_entry_image_$entryId');
  }

  /// Summary macro card.
  static Key summaryMacroCard(String macro) {
    return Key('calories_summary_macro_card_$macro');
  }

  /// Summary macro value.
  static Key summaryMacroValue(String macro) {
    return Key('calories_summary_macro_value_$macro');
  }

  /// Summary macro bar.
  static Key summaryMacroBar(String macro) {
    return Key('calories_summary_macro_bar_$macro');
  }
}

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

/// Defines calorie entry detail keys.
abstract final class CalorieEntryDetailKeys {
  /// The logged day button.
  static const loggedDayButton = Key('calorie_entry_detail_logged_day_button');

  /// The selected meal dropdown.
  static const mealSelector = Key('calorie_entry_detail_meal_selector');

  /// The nutrition strip.
  static const nutritionStrip = Key('calorie_entry_detail_nutrition_strip');

  /// The amount value.
  static const amountValue = Key('calorie_entry_detail_amount_value');

  /// The brand value.
  static const brandValue = Key('calorie_entry_detail_brand_value');

  /// The return to inventory button.
  static const returnToInventoryButton = Key(
    'calorie_entry_detail_return_to_inventory_button',
  );

  /// The ingredients table.
  static const ingredientsTable = Key('calorie_entry_detail_ingredients_table');

  /// Ingredient name cell.
  static Key ingredientNameCell(int index) {
    return Key('calorie_entry_detail_ingredient_name_$index');
  }

  /// Ingredient amount cell.
  static Key ingredientAmountCell(int index) {
    return Key('calorie_entry_detail_ingredient_amount_$index');
  }

  /// Ingredient kcal cell.
  static Key ingredientKcalCell(int index) {
    return Key('calorie_entry_detail_ingredient_kcal_$index');
  }
}
