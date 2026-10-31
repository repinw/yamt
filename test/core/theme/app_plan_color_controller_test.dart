import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_plan_color_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts without a color when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(appPlanColorControllerProvider), isNull);
  });

  test('starts with the saved color', () {
    final container = containerWith(
      MemoryAppPreferences(initialInts: {'app_plan_color_v1': 0xFF2E7D32}),
    );

    expect(
      container.read(appPlanColorControllerProvider),
      const Color(0xFF2E7D32),
    );
  });

  test('select switches at once and saves for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final subscription = container.listen(
      appPlanColorControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container
        .read(appPlanColorControllerProvider.notifier)
        .select(const Color(0xFF7C3AED));

    expect(subscription.read(), const Color(0xFF7C3AED));
    expect(
      containerWith(preferences).read(appPlanColorControllerProvider),
      const Color(0xFF7C3AED),
    );
  });

  test('reset goes back to the default and forgets the saved color', () async {
    final preferences = MemoryAppPreferences(
      initialInts: {'app_plan_color_v1': 0xFF2E7D32},
    );
    final container = containerWith(preferences);
    final subscription = container.listen(
      appPlanColorControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(appPlanColorControllerProvider.notifier).reset();

    expect(subscription.read(), isNull);
    expect(
      containerWith(preferences).read(appPlanColorControllerProvider),
      isNull,
    );
  });
}
