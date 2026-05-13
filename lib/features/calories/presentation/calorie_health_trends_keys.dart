import 'package:flutter/widgets.dart';

/// Defines calorie health trends widget keys.
abstract final class CalorieHealthTrendsKeys {
  /// The weight dialog field.
  static const weightDialogField = Key('calorie_health_trends_weight_field');

  /// The weight dialog clear button.
  static const weightDialogClearButton = Key(
    'calorie_health_trends_weight_clear_button',
  );

  /// The weight dialog save button.
  static const weightDialogSaveButton = Key(
    'calorie_health_trends_weight_save_button',
  );

  /// Weight row.
  static Key weightRow(String dayKey) {
    return Key('calorie_health_trends_weight_row_$dayKey');
  }

  /// Weight action button.
  static Key weightActionButton(String dayKey) {
    return Key('calorie_health_trends_weight_action_$dayKey');
  }
}
