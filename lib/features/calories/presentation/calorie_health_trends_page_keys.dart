import 'package:flutter/widgets.dart';

abstract final class CalorieHealthTrendsPageKeys {
  static const weightDialogField = Key('calorie_health_trends_weight_field');
  static const weightDialogClearButton = Key(
    'calorie_health_trends_weight_clear_button',
  );
  static const weightDialogSaveButton = Key(
    'calorie_health_trends_weight_save_button',
  );

  static Key weightRow(String dayKey) {
    return Key('calorie_health_trends_weight_row_$dayKey');
  }

  static Key weightActionButton(String dayKey) {
    return Key('calorie_health_trends_weight_action_$dayKey');
  }
}
