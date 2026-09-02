import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  group('MacroGoalSettingsController', () {
    test('initializes with default settings when preferences are empty', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final settings = container.read(macroGoalSettingsControllerProvider);

      expect(settings.isSportActive, isTrue);
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
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
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
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
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
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
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

    test(
      'resetToDefaults clears custom multipliers but preserves activity',
      () async {
        final preferences = MemoryAppPreferences();
        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          macroGoalSettingsControllerProvider.notifier,
        );
        await controller.setSportActive(isSportActive: false);
        await controller.setCustomMultipliers(
          proteinMultiplier: 2.5,
          fatMultiplier: 1.3,
        );

        await controller.resetToDefaults();

        final current = container.read(macroGoalSettingsControllerProvider);
        expect(current.isSportActive, isFalse);
        expect(current.customProteinMultiplier, isNull);
        expect(current.customFatMultiplier, isNull);
        // Effective multipliers revert to inactive defaults (1.2 P, 0.9 F
        // for male).
        expect(current.effectiveProteinMultiplier(isMale: true), 1.2);
        expect(current.effectiveFatMultiplier(isMale: true), 0.9);
      },
    );
  });
}
