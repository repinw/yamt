import 'package:flutter/widgets.dart';

abstract final class CaloriesPageKeys {
  static const dayBackButton = Key('calories_day_back_button');
  static const dayTodayButton = Key('calories_day_today_button');
  static const dayForwardButton = Key('calories_day_forward_button');
  static const summaryCard = Key('calories_summary_card');
  static const setGoalButton = Key('calories_set_goal_button');
  static const retryButton = Key('calories_retry_button');
  static const addOptionsManualButton = Key('calories_add_options_manual');
  static const addOptionsBarcodeButton = Key('calories_add_options_barcode');

  static Key sectionCard(String mealType) {
    return Key('calories_section_card_$mealType');
  }

  static Key entryTile(String entryId) {
    return Key('calories_entry_tile_$entryId');
  }

  static Key entryDeleteButton(String entryId) {
    return Key('calories_entry_delete_$entryId');
  }
}

abstract final class CalorieGoalDialogKeys {
  static const valueField = Key('calorie_goal_value_field');
  static const saveButton = Key('calorie_goal_save_button');
  static const clearButton = Key('calorie_goal_clear_button');
}

abstract final class CalorieEntryEditorKeys {
  static const nameField = Key('calorie_entry_name_field');
  static const mealField = Key('calorie_entry_meal_field');
  static const amountField = Key('calorie_entry_amount_field');
  static const unitField = Key('calorie_entry_unit_field');
  static const per100KcalField = Key('calorie_entry_per100_kcal_field');
  static const per100ProteinField = Key('calorie_entry_per100_protein_field');
  static const per100CarbsField = Key('calorie_entry_per100_carbs_field');
  static const per100FatField = Key('calorie_entry_per100_fat_field');
  static const dateButton = Key('calorie_entry_date_button');
  static const timeButton = Key('calorie_entry_time_button');
  static const saveButton = Key('calorie_entry_save_button');
}

abstract final class CalorieBarcodeScanKeys {
  static const scannerView = Key('calorie_barcode_scanner_view');
  static const candidateSheet = Key('calorie_barcode_candidate_sheet');
  static const notFoundDialog = Key('calorie_barcode_not_found_dialog');
  static const notFoundManualButton = Key('calorie_barcode_not_found_manual');
  static const notFoundOcrButton = Key('calorie_barcode_not_found_ocr');
}
