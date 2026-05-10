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

    test('light and dark themes keep scaffold transparent and tint canvas', () {
      expect(light.scaffoldBackgroundColor, Colors.transparent);
      expect(dark.scaffoldBackgroundColor, Colors.transparent);
      expect(
        light.canvasColor,
        equals(
          Color.alphaBlend(
            light.colorScheme.primary.withValues(
              alpha: AppThemeBackground.lightTintAlpha,
            ),
            light.colorScheme.surface,
          ),
        ),
      );
      expect(
        dark.canvasColor,
        equals(
          Color.alphaBlend(
            dark.colorScheme.primary.withValues(
              alpha: AppThemeBackground.darkTintAlpha,
            ),
            dark.colorScheme.surface,
          ),
        ),
      );
      expect(
        AppThemeBackground.darkTintAlpha,
        greaterThan(AppThemeBackground.lightTintAlpha),
      );
      expect(light.appBarTheme.backgroundColor, Colors.transparent);
      expect(dark.appBarTheme.backgroundColor, Colors.transparent);
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
        equals(
          light.colorScheme.outlineVariant.withValues(
            alpha: AppThemeBackground.lightCardBorderAlpha,
          ),
        ),
      );
      expect(
        darkShape.side.color,
        equals(
          dark.colorScheme.outlineVariant.withValues(
            alpha: AppThemeBackground.darkCardBorderAlpha,
          ),
        ),
      );
    });
  });
}
