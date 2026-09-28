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

    test('setSportActive updates state and persists to preferences', () async {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        macroGoalSettingsControllerProvider.notifier,
      );
      await controller.setSportActive(isSportActive: false);

      final current = container.read(macroGoalSettingsControllerProvider);
      expect(current.isSportActive, isFalse);

      final storedJson = preferences.getStringSync('macro_goal_settings_v1');
      expect(storedJson, isNotNull);
      final restored = MacroGoalSettings.fromJsonString(storedJson);
      expect(restored?.isSportActive, isFalse);
    });

    test('setCustomMultipliers updates state and persists', () async {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        macroGoalSettingsControllerProvider.notifier,
      );
      await controller.setCustomMultipliers(
        proteinMultiplier: 2.4,
        fatMultiplier: 1.1,
      );

      final current = container.read(macroGoalSettingsControllerProvider);
      expect(current.customProteinMultiplier, 2.4);
      expect(current.customFatMultiplier, 1.1);

      final storedJson = preferences.getStringSync('macro_goal_settings_v1');
      final restored = MacroGoalSettings.fromJsonString(storedJson);
      expect(restored?.customProteinMultiplier, 2.4);
      expect(restored?.customFatMultiplier, 1.1);
    });
  });
}
