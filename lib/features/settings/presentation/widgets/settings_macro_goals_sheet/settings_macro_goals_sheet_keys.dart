import 'package:material_ui/material_ui.dart';

/// Stable keys for Macro Goals Sheet widget tests.
abstract final class SettingsMacroGoalsSheetKeys {
  /// Sport active switch key.
  static const sportActiveSwitch = ValueKey<String>(
    'settings-macro-goals-sport-switch',
  );

  /// Protein slider key.
  static const proteinSlider = ValueKey<String>(
    'settings-macro-goals-protein-slider',
  );

  /// Fat slider key.
  static const fatSlider = ValueKey<String>('settings-macro-goals-fat-slider');

  /// Reset to recommendations button key.
  static const resetButton = ValueKey<String>(
    'settings-macro-goals-reset-button',
  );

  /// Save button key.
  static const saveButton = ValueKey<String>(
    'settings-macro-goals-save-button',
  );
}
