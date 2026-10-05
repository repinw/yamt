import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme_mode_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('follows the system when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(appThemeModeControllerProvider), ThemeMode.system);
  });

  test('starts with the saved mode', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'dark'}),
    );

    expect(container.read(appThemeModeControllerProvider), ThemeMode.dark);
  });

  test('follows the system for a mode this version does not know', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'sepia'}),
    );

    expect(container.read(appThemeModeControllerProvider), ThemeMode.system);
  });

  test(
    'select switches at once and saves the choice for the next start',
    () async {
      final preferences = MemoryAppPreferences();
      final container = containerWith(preferences);
      final subscription = container.listen(
        appThemeModeControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(appThemeModeControllerProvider.notifier)
          .select(ThemeMode.light);

      expect(subscription.read(), ThemeMode.light);
      expect(
        containerWith(preferences).read(appThemeModeControllerProvider),
        ThemeMode.light,
      );
    },
  );
}
