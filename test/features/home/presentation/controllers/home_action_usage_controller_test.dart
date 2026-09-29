import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/home/presentation/controllers/'
    'home_action_usage_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

ProviderContainer _container(MemoryAppPreferences preferences) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts without counts', () {
    final container = _container(MemoryAppPreferences());

    expect(container.read(homeActionUsageControllerProvider), isEmpty);
  });

  test('counts taps and keeps them for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = _container(preferences);
    final subscription = container.listen(
      homeActionUsageControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      homeActionUsageControllerProvider.notifier,
    );

    await controller.record('barcode');
    await controller.record('barcode');
    await controller.record('search');

    expect(container.read(homeActionUsageControllerProvider), {
      'barcode': 2,
      'search': 1,
    });
    expect(_container(preferences).read(homeActionUsageControllerProvider), {
      'barcode': 2,
      'search': 1,
    });
  });
}
