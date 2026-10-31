import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_recent_colors_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  AppRecentColorsController controllerOf(ProviderContainer container) {
    final subscription = container.listen(
      appRecentColorsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(appRecentColorsControllerProvider.notifier);
  }

  List<int> argb(List<Color> colors) => [
    for (final color in colors) color.toARGB32(),
  ];

  const red = Color(0xFFFF0000);
  const green = Color(0xFF00FF00);

  test('starts empty and puts a taken color first', () async {
    final container = containerWith(MemoryAppPreferences());
    final controller = controllerOf(container);
    expect(container.read(appRecentColorsControllerProvider), isEmpty);

    await controller.add(red);
    await controller.add(green);

    expect(argb(container.read(appRecentColorsControllerProvider)), [
      green.toARGB32(),
      red.toARGB32(),
    ]);
  });

  test(
    'a color taken again moves to the front instead of showing twice',
    () async {
      final container = containerWith(MemoryAppPreferences());
      final controller = controllerOf(container);

      await controller.add(red);
      await controller.add(green);
      await controller.add(red);

      expect(argb(container.read(appRecentColorsControllerProvider)), [
        red.toARGB32(),
        green.toARGB32(),
      ]);
    },
  );

  test('keeps the six newest colors', () async {
    final container = containerWith(MemoryAppPreferences());
    final controller = controllerOf(container);
    final colors = [for (var i = 1; i <= 7; i++) Color(0xFF000000 + i)];

    for (final color in colors) {
      await controller.add(color);
    }

    expect(
      argb(container.read(appRecentColorsControllerProvider)),
      argb(colors.reversed.take(6).toList()),
    );
  });

  test('a new start reads the saved colors back', () async {
    final preferences = MemoryAppPreferences();
    final controller = controllerOf(containerWith(preferences));
    await controller.add(red);
    await controller.add(green);

    final restarted = containerWith(preferences);

    expect(argb(restarted.read(appRecentColorsControllerProvider)), [
      green.toARGB32(),
      red.toARGB32(),
    ]);
  });

  test('keeps a color added while nothing watches the colors', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    // The panel that started the add closes while the color saves.
    final adding = container
        .read(appRecentColorsControllerProvider.notifier)
        .add(red);
    await container.pump();
    await adding;

    expect(argb(container.read(appRecentColorsControllerProvider)), [
      red.toARGB32(),
    ]);
    expect(
      preferences.getStringSync('app_recent_colors_v1'),
      '${red.toARGB32()}',
    );
  });
}
