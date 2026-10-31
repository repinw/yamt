import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_design_controller.dart';

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

    expect(container.read(appDesignControllerProvider), AppDesign.system);
  });

  test('starts with the saved mode', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'dark'}),
    );

    expect(container.read(appDesignControllerProvider), AppDesign.dark);
  });

  test('starts with the saved custom design', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'custom'}),
    );

    expect(container.read(appDesignControllerProvider), AppDesign.custom);
  });

  test('follows the system for a mode this version does not know', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_theme_mode_v1': 'sepia'}),
    );

    expect(container.read(appDesignControllerProvider), AppDesign.system);
  });

  test(
    'select switches at once and saves the choice for the next start',
    () async {
      final preferences = MemoryAppPreferences();
      final container = containerWith(preferences);
      final subscription = container.listen(
        appDesignControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(appDesignControllerProvider.notifier)
          .select(AppDesign.light);

      expect(subscription.read(), AppDesign.light);
      expect(
        containerWith(preferences).read(appDesignControllerProvider),
        AppDesign.light,
      );
    },
  );
}
