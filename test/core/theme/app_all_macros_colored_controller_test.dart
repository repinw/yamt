import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_all_macros_colored_controller.dart';

import '../../helpers/memory_app_preferences.dart';

const _key = 'app_all_macros_colored_v1';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is off by default', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(appAllMacrosColoredControllerProvider), isFalse);
  });

  test('turning it on saves it for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);

    await container
        .read(appAllMacrosColoredControllerProvider.notifier)
        .select(value: true);

    expect(container.read(appAllMacrosColoredControllerProvider), isTrue);
    expect(preferences.getStringSync(_key), '1');
    expect(
      containerWith(preferences).read(appAllMacrosColoredControllerProvider),
      isTrue,
    );
  });

  test('turning it off removes the saved choice', () async {
    final preferences = MemoryAppPreferences(initialStrings: {_key: '1'});
    final container = containerWith(preferences);
    expect(container.read(appAllMacrosColoredControllerProvider), isTrue);

    await container
        .read(appAllMacrosColoredControllerProvider.notifier)
        .select(value: false);

    expect(container.read(appAllMacrosColoredControllerProvider), isFalse);
    expect(preferences.getStringSync(_key), isNull);
  });
}
