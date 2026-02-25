import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/app_theme.dart';

void main() {
  test('light and dark themes tint scaffold background from surface', () {
    final light = AppTheme.light(seedColor: AppColors.seed);
    final dark = AppTheme.dark(seedColor: AppColors.seed);

    expect(light.scaffoldBackgroundColor, isNot(light.colorScheme.surface));
    expect(dark.scaffoldBackgroundColor, isNot(dark.colorScheme.surface));
    expect(
      light.appBarTheme.backgroundColor,
      equals(light.scaffoldBackgroundColor),
    );
    expect(
      dark.appBarTheme.backgroundColor,
      equals(dark.scaffoldBackgroundColor),
    );
  });

  test('theme card style is unified for light and dark', () {
    final light = AppTheme.light(seedColor: AppColors.seed);
    final dark = AppTheme.dark(seedColor: AppColors.seed);

    expect(light.cardTheme.elevation, 0);
    expect(dark.cardTheme.elevation, 0);
    expect(light.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(dark.cardTheme.shape, isA<RoundedRectangleBorder>());
  });
}
