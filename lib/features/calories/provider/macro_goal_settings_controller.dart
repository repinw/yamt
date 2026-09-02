import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

part 'macro_goal_settings_controller.g.dart';

const _macroGoalSettingsKey = 'macro_goal_settings_v1';

/// Manages persisted macro goal settings.
@Riverpod(keepAlive: true)
class MacroGoalSettingsController extends _$MacroGoalSettingsController {
  @override
  MacroGoalSettings build() {
    final preferences = ref.watch(appPreferencesProvider);
    final storedJson = preferences.getStringSync(_macroGoalSettingsKey);
    if (storedJson != null) {
      final parsed = MacroGoalSettings.fromJsonString(storedJson);
      if (parsed != null) {
        return parsed;
      }
    }

    unawaited(_loadSavedSettings());
    return const MacroGoalSettings();
  }

  Future<void> _loadSavedSettings() async {
    final storedJson = await ref
        .read(appPreferencesProvider)
        .getString(_macroGoalSettingsKey);
    if (!ref.mounted || storedJson == null) {
      return;
    }
    final parsed = MacroGoalSettings.fromJsonString(storedJson);
    if (parsed != null) {
      state = parsed;
    }
  }

  /// Updates macro settings and persists them.
  Future<void> updateSettings(MacroGoalSettings nextSettings) async {
    state = nextSettings;
    await ref
        .read(appPreferencesProvider)
        .setString(_macroGoalSettingsKey, nextSettings.toJsonString());
  }

  /// Sets sport activity status.
  Future<void> setSportActive({required bool isSportActive}) async {
    final next = state.copyWith(isSportActive: isSportActive);
    await updateSettings(next);
  }

  /// Sets custom multipliers.
  Future<void> setCustomMultipliers({
    double? proteinMultiplier,
    double? fatMultiplier,
  }) async {
    final next = state.copyWith(
      customProteinMultiplier: proteinMultiplier,
      customFatMultiplier: fatMultiplier,
    );
    await updateSettings(next);
  }

  /// Resets multipliers to defaults for current sex and sport setting.
  Future<void> resetToDefaults() async {
    final next = state.copyWith(
      clearCustomProtein: true,
      clearCustomFat: true,
    );
    await updateSettings(next);
  }
}
