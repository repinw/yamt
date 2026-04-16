import 'package:flutter/widgets.dart';

/// Defines calories page keys.
abstract final class CaloriesPageKeys {
  /// The app bar menu button.
  static const appBarMenuButton = Key('calories_app_bar_menu_button');

  /// The app bar menu calculator action.
  static const appBarMenuCalculatorAction = Key(
    'calories_app_bar_calculator_action',
  );

  /// The app bar menu set eating window action.
  static const appBarMenuSetEatingWindowAction = Key(
    'calories_app_bar_set_eating_window_action',
  );

  /// The app bar menu shift goal start action.
  static const appBarMenuShiftGoalStartAction = Key(
    'calories_app_bar_shift_goal_start_action',
  );

  /// The week strip.
  static const weekStrip = Key('calories_week_strip');

  /// The week buffer card.
  static const weekBufferCard = Key('calories_week_buffer_card');

  /// The week balance chart.
  static const weekBalanceChart = Key('calories_week_balance_chart');

  /// The week balance summary.
  static const weekBalanceSummary = Key('calories_week_balance_summary');

  /// The week balance summary icon.
  static const weekBalanceSummaryIcon = Key(
    'calories_week_balance_summary_icon',
  );

  /// The summary card.
  static const summaryCard = Key('calories_summary_card');

  /// The summary mode toggle.
  static const summaryModeToggle = Key('calories_summary_mode_toggle');

  /// The summary balance bar.
  static const summaryBalanceBar = Key('calories_summary_balance_bar');

  /// The summary activity delta note.
  static const summaryActivityDeltaNote = Key(
    'calories_summary_activity_delta_note',
  );

  /// The summary carryover note.
  static const summaryCarryoverNote = Key(
    'calories_summary_carryover_note',
  );

  /// The summary meta section.
  static const summaryMetaSection = Key('calories_summary_meta_section');

  /// The summary activity delta toggle.
  static const summaryActivityDeltaToggle = Key(
    'calories_summary_activity_delta_toggle',
  );

  /// The summary carryover toggle.
  static const summaryCarryoverToggle = Key(
    'calories_summary_carryover_toggle',
  );

  /// The reload progress indicator.
  static const reloadProgressIndicator = Key(
    'calories_reload_progress_indicator',
  );

  /// The retry button.
  static const retryButton = Key('calories_retry_button');

  /// The weekly check in hint card.
  static const weeklyCheckInHintCard = Key('calories_weekly_checkin_hint_card');

  /// The weekly check in success card.
  static const weeklyCheckInSuccessCard = Key(
    'calories_weekly_checkin_success_card',
  );

  /// The weekly check in continue button.
  static const weeklyCheckInContinueButton = Key(
    'calories_weekly_checkin_continue_button',
  );

  /// The weekly check in open trends button.
  static const weeklyCheckInOpenTrendsButton = Key(
    'calories_weekly_checkin_open_trends_button',
  );

  /// The weekly check in skip day button.
  static const weeklyCheckInSkipDayButton = Key(
    'calories_weekly_checkin_skip_day_button',
  );

  /// The add options manual button.
  static const addOptionsManualButton = Key('calories_add_options_manual');

  /// The add options barcode button.
  static const addOptionsBarcodeButton = Key('calories_add_options_barcode');

  /// Section card.
  static Key sectionCard(String mealType) {
    return Key('calories_section_card_$mealType');
  }

  /// Entry tile.
  static Key entryTile(String entryId) {
    return Key('calories_entry_tile_$entryId');
  }

  /// Delete restore checkbox.
  static Key deleteRestoreCheckbox(String entryId) {
    return Key('calories_delete_restore_$entryId');
  }

  /// Entry image.
  static Key entryImage(String entryId) {
    return Key('calories_entry_image_$entryId');
  }

  /// Bundle component image.
  static Key bundleComponentImage(String entryId, int index) {
    return Key('calories_bundle_component_image_${entryId}_$index');
  }

  /// Section add button.
  static Key sectionAddButton(String mealType) {
    return Key('calories_section_add_$mealType');
  }

  /// Summary mode option.
  static Key summaryModeOption(String mode) {
    return Key('calories_summary_mode_$mode');
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

  /// Week balance day column.
  static Key weekBalanceDayColumn(String dayKey) {
    return Key('calories_week_balance_day_$dayKey');
  }

  /// Week balance bar.
  static Key weekBalanceBar(String dayKey) {
    return Key('calories_week_balance_bar_$dayKey');
  }

  /// Day navigation preview.
  static Key dayNavigationPreview(String dayKey) {
    return Key('calories_day_navigation_preview_$dayKey');
  }

  /// Day navigation preview goal line.
  static Key dayNavigationPreviewGoalLine(String dayKey) {
    return Key('calories_day_navigation_preview_goal_line_$dayKey');
  }

  /// Day navigation preview bar.
  static Key dayNavigationPreviewBar(String dayKey) {
    return Key('calories_day_navigation_preview_bar_$dayKey');
  }
}

/// Defines calorie goal dialog keys.
abstract final class CalorieGoalDialogKeys {
  /// The value field.
  static const valueField = Key('calorie_goal_value_field');

  /// The clear button.
  static const clearButton = Key('calorie_goal_clear_button');
}

/// Defines calorie goal start dialog keys.
abstract final class CalorieGoalStartDialogKeys {
  /// The change date button.
  static const changeDateButton = Key('calorie_goal_start_change_date_button');

  /// The change time button.
  static const changeTimeButton = Key('calorie_goal_start_change_time_button');

  /// The save button.
  static const saveButton = Key('calorie_goal_start_save_button');
}

/// Defines calorie goal calculator sheet keys.
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

  /// The eating window card.
  static const eatingWindowCard = Key('calorie_calculator_eating_window_card');

  /// The eating window value.
  static const eatingWindowValue = Key(
    'calorie_calculator_eating_window_value',
  );

  /// The eating window change button.
  static const eatingWindowChangeButton = Key(
    'calorie_calculator_eating_window_change_button',
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

/// Defines calorie weekly check in dialog keys.
abstract final class CalorieWeeklyCheckInDialogKeys {
  /// The dialog.
  static const dialog = Key('calorie_weekly_checkin_dialog');

  /// The later button.
  static const laterButton = Key('calorie_weekly_checkin_later_button');

  /// The apply button.
  static const applyButton = Key('calorie_weekly_checkin_apply_button');

  /// The open trends button.
  static const openTrendsButton = Key(
    'calorie_weekly_checkin_open_trends_button',
  );
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

/// Defines calorie eating window dialog keys.
abstract final class CalorieEatingWindowDialogKeys {
  /// The change start button.
  static const changeStartButton = Key(
    'calorie_eating_window_change_start_button',
  );

  /// The change end button.
  static const changeEndButton = Key('calorie_eating_window_change_end_button');

  /// The save button.
  static const saveButton = Key('calorie_eating_window_save_button');
}

/// Defines calorie barcode scan keys.
abstract final class CalorieBarcodeScanKeys {
  /// The candidate sheet.
  static const candidateSheet = Key('calorie_barcode_candidate_sheet');

  /// The not found dialog.
  static const notFoundDialog = Key('calorie_barcode_not_found_dialog');

  /// The not found manual button.
  static const notFoundManualButton = Key('calorie_barcode_not_found_manual');

  /// The not found ocr button.
  static const notFoundOcrButton = Key('calorie_barcode_not_found_ocr');
}
