import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_themes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

import '../../helpers/memory_app_preferences.dart';

void main() {
  AppThemes themesWith(Map<String, String> strings) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(initialStrings: strings),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container.read(appThemesProvider);
  }

  String customJson(Brightness base) => jsonEncode(
    AppCustomColors.copyOf(
      base == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    ).withColor(AppCustomColor.paper, const Color(0xFF123456)).toJson(),
  );

  for (final (design, mode) in [
    ('system', ThemeMode.system),
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    test('$design shows the Graphit themes', () {
      final themes = themesWith({'app_theme_mode_v1': design});

      expect(themes.mode, mode);
      expect(
        themes.light.extension<FoodLabelColors>()!.paper,
        FoodLabelColors.light.paper,
      );
      expect(
        themes.dark.extension<FoodLabelColors>()!.paper,
        FoodLabelColors.dark.paper,
      );
    });
  }

  test('custom shows the own colors whatever the system brightness', () {
    for (final (base, mode) in [
      (Brightness.light, ThemeMode.light),
      (Brightness.dark, ThemeMode.dark),
    ]) {
      final themes = themesWith({
        'app_theme_mode_v1': 'custom',
        'app_custom_colors_v1': customJson(base),
      });

      expect(themes.mode, mode);
      for (final theme in [themes.light, themes.dark]) {
        expect(theme.colorScheme.surface, const Color(0xFF123456));
        expect(theme.brightness, base);
      }
    }
  });

  test('custom without saved colors follows the system', () {
    final themes = themesWith({'app_theme_mode_v1': 'custom'});

    expect(themes.mode, ThemeMode.system);
  });
}
