import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  test('seed color defaults to app seed', () {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(seedColorControllerProvider).toARGB32(),
      AppColors.seed.toARGB32(),
    );
  });

  test('seed color can be updated and persisted', () async {
    final preferences = MemoryAppPreferences();
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(seedColorControllerProvider.notifier)
        .setSeedColor(const Color(0xFF0D47A1));

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF0D47A1);
    expect(await preferences.getInt('preferred_seed_color'), 0xFF0D47A1);
  });
}
