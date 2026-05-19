import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

void main() {
  group('AppTheme', () {
    late final ThemeData light;
    late final ThemeData dark;

    setUpAll(() {
      light = AppTheme.light(seedColor: AppColors.seed);
      dark = AppTheme.dark(seedColor: AppColors.seed);
    });

    test('light and dark themes use editorial canvas surfaces', () {
      expect(light.scaffoldBackgroundColor, Colors.transparent);
      expect(dark.scaffoldBackgroundColor, Colors.transparent);
      expect(
        light.canvasColor,
        AppEditorialSurfaces.appBackground(light.colorScheme),
      );
      expect(
        dark.canvasColor,
        AppEditorialSurfaces.appBackground(dark.colorScheme),
      );
      expect(
        AppThemeBackground.darkTintAlpha,
        greaterThan(AppThemeBackground.lightTintAlpha),
      );
      expect(light.appBarTheme.backgroundColor, light.canvasColor);
      expect(dark.appBarTheme.backgroundColor, dark.canvasColor);
      expect(
        light.bottomNavigationBarTheme.backgroundColor,
        AppEditorialSurfaces.section(light.colorScheme),
      );
      expect(
        dark.bottomNavigationBarTheme.backgroundColor,
        AppEditorialSurfaces.section(dark.colorScheme),
      );
    });

    test('theme card style is unified for light and dark', () {
      expect(light.cardTheme.elevation, 0);
      expect(dark.cardTheme.elevation, 0);
      expect(light.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(dark.cardTheme.shape, isA<RoundedRectangleBorder>());

      final lightShape = light.cardTheme.shape! as RoundedRectangleBorder;
      final darkShape = dark.cardTheme.shape! as RoundedRectangleBorder;
      expect(
        lightShape.side.color,
        AppEditorialSurfaces.solidCardBorder(light.colorScheme),
      );
      expect(
        darkShape.side.color,
        AppEditorialSurfaces.solidCardBorder(dark.colorScheme),
      );
    });

    test('Material widgets keep their built-in feedback available', () {
      expect(light.bottomNavigationBarTheme.enableFeedback, isNull);
      expect(light.filledButtonTheme.style?.enableFeedback, isNull);
      expect(light.outlinedButtonTheme.style?.enableFeedback, isNull);
      expect(light.elevatedButtonTheme.style?.enableFeedback, isNull);
      expect(light.textButtonTheme.style?.enableFeedback, isNull);
      expect(light.iconButtonTheme.style?.enableFeedback, isNull);
      expect(light.floatingActionButtonTheme.enableFeedback, isNull);
      expect(light.listTileTheme.enableFeedback, isNull);
      expect(light.popupMenuTheme.enableFeedback, isNull);
      expect(light.segmentedButtonTheme.style?.enableFeedback, isNull);
      expect(light.tooltipTheme.enableFeedback, isNull);
    });
  });
}
