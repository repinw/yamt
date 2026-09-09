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

  /// Calorie goal intro row.
  static const calorieGoalIntroTile = ValueKey<String>(
    'settings-calorie-goal-intro-tile',
  );

  /// Language row.
  static const languageTile = ValueKey<String>('settings-language-tile');

  /// Notifications row.
  static const notificationsTile = ValueKey<String>(
    'settings-notifications-tile',
  );

  /// Privacy row.
  static const privacyTile = ValueKey<String>('settings-privacy-tile');

  /// About row.
  static const aboutTile = ValueKey<String>('settings-about-tile');

  /// About trailing area for version/loading/error assertions.
  static const aboutTrailing = ValueKey<String>('settings-about-trailing');
}
