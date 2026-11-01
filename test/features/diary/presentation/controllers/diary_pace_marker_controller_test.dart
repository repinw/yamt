import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _key = 'diary_pace_marker_v1';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is off until the user turns it on', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(diaryPaceMarkerControllerProvider), isFalse);
  });

  test('starts on when it was saved as on', () {
    final container = containerWith(
      MemoryAppPreferences(initialInts: {_key: 1}),
    );

    expect(container.read(diaryPaceMarkerControllerProvider), isTrue);
  });

  test('a saved value that is not 1 starts off', () {
    for (final value in [0, 2, -1]) {
      final container = containerWith(
        MemoryAppPreferences(initialInts: {_key: value}),
      );

      expect(
        container.read(diaryPaceMarkerControllerProvider),
        isFalse,
        reason: '$value',
      );
    }
  });

  test('showing it switches at once and saves it as 1', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final states = <bool>[];
    final subscription = container.listen(
      diaryPaceMarkerControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container
        .read(diaryPaceMarkerControllerProvider.notifier)
        .show(visible: true);

    expect(states, [false, true]);
    expect(preferences.getIntSync(_key), 1);
    expect(
      containerWith(preferences).read(diaryPaceMarkerControllerProvider),
      isTrue,
    );
  });

  test('hiding it switches at once and forgets the saved value', () async {
    final preferences = MemoryAppPreferences(initialInts: {_key: 1});
    final container = containerWith(preferences);
    final states = <bool>[];
    final subscription = container.listen(
      diaryPaceMarkerControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container
        .read(diaryPaceMarkerControllerProvider.notifier)
        .show(visible: false);

    expect(states, [true, false]);
    expect(preferences.getIntSync(_key), isNull);
    expect(await preferences.keys(), isNot(contains(_key)));
    expect(
      containerWith(preferences).read(diaryPaceMarkerControllerProvider),
      isFalse,
    );
  });
}
