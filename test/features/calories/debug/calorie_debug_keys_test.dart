import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/debug/calorie_debug_keys.dart';

void main() {
  test('calorie debug keys generate stable values', () {
    expect(
      CalorieDebugKeys.actionsMenuButton,
      const Key('calories_debug_actions_menu_button'),
    );
    expect(
      CalorieDebugKeys.debugDumpButton,
      const Key('calories_debug_dump_button'),
    );
    expect(
      CalorieDebugKeys.settingsDebugDumpButton,
      const Key('calories_settings_debug_dump_button'),
    );
    expect(
      CalorieDebugKeys.weeklyCheckInDebugDumpButton,
      const Key('calories_weekly_checkin_debug_dump_button'),
    );
  });
}
