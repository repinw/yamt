import 'package:flutter/widgets.dart';

/// Defines stable keys for calorie debug UI.
abstract final class CalorieDebugKeys {
  /// Opens calorie debug actions.
  static const actionsMenuButton = Key('calories_debug_actions_menu_button');

  /// Prints calorie debug dump.
  static const debugDumpButton = Key('calories_debug_dump_button');

  /// Prints calorie settings debug dump.
  static const settingsDebugDumpButton = Key(
    'calories_settings_debug_dump_button',
  );

  /// Prints calorie weekly check-in debug dump.
  static const weeklyCheckInDebugDumpButton = Key(
    'calories_weekly_checkin_debug_dump_button',
  );
}
