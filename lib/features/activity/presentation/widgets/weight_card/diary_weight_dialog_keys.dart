import 'package:flutter/widgets.dart';

/// Widget keys for diary weight dialogs.
abstract final class DiaryWeightDialogKeys {
  /// Weight text field.
  static const weightDialogField = Key('diary_weight_dialog_field');

  /// Clear button.
  static const weightDialogClearButton = Key(
    'diary_weight_dialog_clear_button',
  );

  /// Save button.
  static const weightDialogSaveButton = Key(
    'diary_weight_dialog_save_button',
  );
}
