import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  test('theme mode defaults to system', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('theme mode can be updated and persisted', () async {
    final preferences = MemoryAppPreferences();
    final overrideContainer = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(overrideContainer.dispose);

    await overrideContainer
        .read(themeModeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(overrideContainer.read(themeModeControllerProvider), ThemeMode.dark);
    expect(
      await preferences.getString('preferred_theme_mode'),
      ThemeMode.dark.name,
    );
  });
}
