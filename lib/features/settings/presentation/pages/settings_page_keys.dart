import 'package:flutter/widgets.dart';

/// Stable keys for the settings page.
abstract final class SettingsPageKeys {
  /// Profile summary card.
  static const profileCard = ValueKey<String>('settings-profile-card');

  /// Household navigation row.
  static const householdTile = ValueKey<String>('settings-household-tile');

  /// Account navigation row.
  static const accountTile = ValueKey<String>('settings-account-tile');

  /// Health connection row.
  static const healthConnectTile = ValueKey<String>(
    'settings-health-connect-tile',
  );

  /// Calorie goal start row.
  static const calorieGoalStartTile = ValueKey<String>(
    'settings-calorie-goal-start-tile',
  );

  /// Calorie calculator row.
  static const calorieGoalCalculatorTile = ValueKey<String>(
    'settings-calorie-goal-calculator-tile',
  );

  /// Macro goals distribution row.
  static const macroGoalsTile = ValueKey<String>('settings-macro-goals-tile');

  /// Language row.
  static const languageTile = ValueKey<String>('settings-language-tile');

  /// Design row (System, Light, Dark, Custom).
  static const designTile = ValueKey<String>('settings-theme-mode-tile');

  /// Accent color row.
  static const accentTile = ValueKey<String>('settings-accent-tile');

  /// Row that opens the color editor of the design "Individuell".
  static const customColorsTile = ValueKey<String>(
    'settings-custom-colors-tile',
  );

  /// Day-before reminder switch row.
  static const planShortageReminderTile = ValueKey<String>(
    'settings-plan-shortage-reminder-tile',
  );

  /// Day-before reminder time row.
  static const planShortageReminderTimeTile = ValueKey<String>(
    'settings-plan-shortage-reminder-time-tile',
  );

  /// Privacy row.
  static const privacyTile = ValueKey<String>('settings-privacy-tile');

  /// Tile that opens the data export.
  static const dataExportTile = ValueKey<String>('settings-data-export-tile');

  /// About row.
  static const aboutTile = ValueKey<String>('settings-about-tile');

  /// Home-screen widget verbose-mode row.
  static const homeWidgetVerboseModeTile = ValueKey<String>(
    'settings-home-widget-verbose-mode-tile',
  );

  /// About trailing area for version/loading/error assertions.
  static const aboutTrailing = ValueKey<String>('settings-about-trailing');
}
