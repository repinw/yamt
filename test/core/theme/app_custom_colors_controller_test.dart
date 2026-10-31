import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_custom_colors_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  AppCustomColorsController controllerOf(ProviderContainer container) {
    final subscription = container.listen(
      appCustomColorsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(appCustomColorsControllerProvider.notifier);
  }

  const picked = Color(0xFF2E7D32);

  test('has no colors before the design is first picked', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(appCustomColorsControllerProvider), isNull);
  });

  test(
    'start copies the light or dark design with the picked accent',
    () async {
      final preferences = MemoryAppPreferences(
        initialStrings: {'app_accent_v1': 'pink'},
      );
      final container = containerWith(preferences);

      await controllerOf(container).start(Brightness.dark);

      expect(
        container.read(appCustomColorsControllerProvider),
        AppCustomColors.copyOf(AppTheme.dark(accent: AppAccent.pink)),
      );
    },
  );

  test('a picked color survives a restart', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final controller = controllerOf(container);

    await controller.start(Brightness.light);
    await controller.select(AppCustomColor.protein, picked);

    final restored = containerWith(preferences)
        .read(appCustomColorsControllerProvider)!;
    expect(restored[AppCustomColor.protein], picked);
    expect(restored.base, Brightness.light);
    expect(
      jsonDecode(preferences.getStringSync('app_custom_colors_v1')!),
      restored.toJson(),
    );
  });

  test('starting over replaces the picked colors with a fresh copy', () async {
    final container = containerWith(MemoryAppPreferences());
    final controller = controllerOf(container);

    await controller.start(Brightness.dark);
    await controller.select(AppCustomColor.paper, picked);
    await controller.start(Brightness.light);

    expect(
      container.read(appCustomColorsControllerProvider),
      AppCustomColors.copyOf(AppTheme.light()),
    );
  });
}
