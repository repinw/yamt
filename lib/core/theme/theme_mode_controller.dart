import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'theme_mode_controller.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const String _themeModeKey = 'preferred_theme_mode';

  @override
  ThemeMode build() {
    final preferences = ref.read(appPreferencesProvider);
    final storedMode = preferences.getStringSync(_themeModeKey);
    if (storedMode != null) {
      return _themeModeFromName(storedMode);
    }

    unawaited(_loadSavedThemeMode());
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    await ref.read(appPreferencesProvider).setString(_themeModeKey, mode.name);
  }

  Future<void> _loadSavedThemeMode() async {
    final storedMode = await ref
        .read(appPreferencesProvider)
        .getString(_themeModeKey);
    if (!ref.mounted || storedMode == null) {
      return;
    }

    state = _themeModeFromName(storedMode);
  }

  ThemeMode _themeModeFromName(String mode) {
    return switch (mode) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
