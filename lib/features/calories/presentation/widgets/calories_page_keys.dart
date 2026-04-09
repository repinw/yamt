import 'package:flutter/widgets.dart';

abstract final class CaloriesPageKeys {
  static const appBarMenuButton = Key('calories_app_bar_menu_button');
  static const appBarMenuCalculatorAction = Key(
    'calories_app_bar_calculator_action',
  );
  static const weekStrip = Key('calories_week_strip');
  static const weekBufferCard = Key('calories_week_buffer_card');
  static const weekBalanceChart = Key('calories_week_balance_chart');
  static const weekBalanceSummary = Key('calories_week_balance_summary');
  static const weekBalanceSummaryIcon = Key(
    'calories_week_balance_summary_icon',
  );
  static const summaryCard = Key('calories_summary_card');
  static const summaryModeToggle = Key('calories_summary_mode_toggle');
  static const summaryBalanceBar = Key('calories_summary_balance_bar');
  static const reloadProgressIndicator = Key(
    'calories_reload_progress_indicator',
  );
  static const retryButton = Key('calories_retry_button');
  static const addOptionsManualButton = Key('calories_add_options_manual');
  static const addOptionsBarcodeButton = Key('calories_add_options_barcode');

  static Key sectionCard(String mealType) {
    return Key('calories_section_card_$mealType');
  }

  static Key entryTile(String entryId) {
    return Key('calories_entry_tile_$entryId');
  }

  static Key deleteRestoreCheckbox(String entryId) {
    return Key('calories_delete_restore_$entryId');
  }

  static Key entryImage(String entryId) {
    return Key('calories_entry_image_$entryId');
  }

  static Key bundleComponentImage(String entryId, int index) {
    return Key('calories_bundle_component_image_${entryId}_$index');
  }

  static Key sectionAddButton(String mealType) {
    return Key('calories_section_add_$mealType');
  }

  static Key summaryModeOption(String mode) {
    return Key('calories_summary_mode_$mode');
  }

  static Key weekBalanceDayColumn(String dayKey) {
    return Key('calories_week_balance_day_$dayKey');
  }

  static Key weekBalanceBar(String dayKey) {
    return Key('calories_week_balance_bar_$dayKey');
  }
}

abstract final class CalorieGoalDialogKeys {
  static const valueField = Key('calorie_goal_value_field');
  static const clearButton = Key('calorie_goal_clear_button');
}

abstract final class CalorieGoalCalculatorSheetKeys {
  static const stepCounter = Key('calorie_calculator_step_counter');
  static const weightField = Key('calorie_calculator_weight_field');
  static const heightField = Key('calorie_calculator_height_field');
  static const ageField = Key('calorie_calculator_age_field');
  static const activityLevelOptions = Key(
    'calorie_calculator_activity_level_options',
  );
  static const goalModeSegment = Key('calorie_calculator_goal_mode_segment');
  static const goalSpeedField = Key('calorie_calculator_goal_speed_field');
  static const resultsCard = Key('calorie_calculator_results_card');
  static const warningCard = Key('calorie_calculator_warning_card');
  static const backButton = Key('calorie_calculator_back_button');
  static const nextButton = Key('calorie_calculator_next_button');
  static const saveButton = Key('calorie_calculator_save_button');

  static Key activityLevelOption(String optionId) {
    return Key('calorie_calculator_activity_level_option_$optionId');
  }
}

abstract final class CalorieEntryEditorKeys {
  static const nameField = Key('calorie_entry_name_field');
  static const amountField = Key('calorie_entry_amount_field');
  static const unitField = Key('calorie_entry_unit_field');
  static const per100KcalField = Key('calorie_entry_per100_kcal_field');
  static const per100ProteinField = Key('calorie_entry_per100_protein_field');
  static const per100CarbsField = Key('calorie_entry_per100_carbs_field');
  static const per100FatField = Key('calorie_entry_per100_fat_field');
  static const saveButton = Key('calorie_entry_save_button');
}

abstract final class CalorieBarcodeScanKeys {
  static const candidateSheet = Key('calorie_barcode_candidate_sheet');
  static const notFoundDialog = Key('calorie_barcode_not_found_dialog');
  static const notFoundManualButton = Key('calorie_barcode_not_found_manual');
  static const notFoundOcrButton = Key('calorie_barcode_not_found_ocr');
}
