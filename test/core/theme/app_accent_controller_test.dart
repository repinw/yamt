import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts with lime when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(appAccentControllerProvider), AppAccent.lime);
  });

  test('starts with the saved accent', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_accent_v1': 'pink'}),
    );

    expect(container.read(appAccentControllerProvider), AppAccent.pink);
  });

  test('falls back to lime for an accent this version does not know', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {'app_accent_v1': 'sky'}),
    );

    expect(container.read(appAccentControllerProvider), AppAccent.lime);
  });

  test(
    'select switches at once and saves the choice for the next start',
    () async {
      final preferences = MemoryAppPreferences();
      final container = containerWith(preferences);
      final subscription = container.listen(
        appAccentControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(appAccentControllerProvider.notifier)
          .select(AppAccent.violet);

      expect(subscription.read(), AppAccent.violet);
      expect(
        containerWith(preferences).read(appAccentControllerProvider),
        AppAccent.violet,
      );
    },
  );
}
