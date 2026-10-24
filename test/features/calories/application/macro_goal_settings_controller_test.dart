import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  group('MacroGoalSettingsController', () {
    test('initializes with default settings when preferences are empty', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final settings = container.read(macroGoalSettingsControllerProvider);

      // Sport follows the training days until the user sets it.
      expect(settings.isSportActive, isNull);
      expect(settings.customProteinMultiplier, isNull);
      expect(settings.customFatMultiplier, isNull);
    });

    test('initializes from stored preferences when present', () {
      const stored = MacroGoalSettings(
        isSportActive: false,
        customProteinMultiplier: 2.2,
        customFatMultiplier: 0.9,
      );
      final preferences = MemoryAppPreferences(
        initialStrings: {'macro_goal_settings_v1': stored.toJsonString()},
      );

      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final settings = container.read(macroGoalSettingsControllerProvider);

      expect(settings.isSportActive, isFalse);
      expect(settings.customProteinMultiplier, 2.2);
      expect(settings.customFatMultiplier, 0.9);
    });
  });
}
