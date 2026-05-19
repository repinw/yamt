import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

void main() {
  test('editorial surfaces keep mock-like contrast in dark mode', () {
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    final background = AppEditorialSurfaces.appBackground(colors);
    final card = AppEditorialSurfaces.liftedCard(colors);
    final section = AppEditorialSurfaces.section(colors);

    expect(ThemeData.estimateBrightnessForColor(background), Brightness.dark);
    expect(ThemeData.estimateBrightnessForColor(card), Brightness.dark);
    expect(ThemeData.estimateBrightnessForColor(section), Brightness.dark);
    expect(card.computeLuminance(), greaterThan(background.computeLuminance()));
    expect(section.computeLuminance(), greaterThan(card.computeLuminance()));
    expect(AppEditorialSurfaces.glass(colors), section);
  });

  test('solid card borders are mode-specific and subtle', () {
    final light = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final dark = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    expect(
      AppEditorialSurfaces.solidCardBorder(light).a,
      closeTo(AppThemeBackground.lightCardBorderAlpha, 0.001),
    );
    expect(
      AppEditorialSurfaces.solidCardBorder(dark).a,
      closeTo(AppThemeBackground.darkCardBorderAlpha, 0.001),
    );
    expect(
      AppThemeBackground.darkCardBorderAlpha,
      lessThan(AppThemeBackground.lightCardBorderAlpha),
    );
  });

  test('compact progress track is derived from lifted card surface', () {
    final light = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final dark = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    expect(
      AppEditorialSurfaces.compactProgressTrack(light),
      isNot(AppEditorialSurfaces.liftedCard(light)),
    );
    expect(
      AppEditorialSurfaces.compactProgressTrack(dark),
      isNot(AppEditorialSurfaces.liftedCard(dark)),
    );
    expect(
      AppEditorialSurfaces.compactProgressTrack(dark).computeLuminance(),
      lessThan(AppEditorialSurfaces.liftedCard(dark).computeLuminance()),
    );
  });

  test('ingredient accents use color scheme roles and cycle', () {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.seed);

    expect(
      AppEditorialSurfaces.ingredientAccent(colors, 0),
      colors.primary,
    );
    expect(
      AppEditorialSurfaces.ingredientAccent(colors, 1),
      colors.secondary,
    );
    expect(
      AppEditorialSurfaces.ingredientAccent(colors, 2),
      colors.tertiary,
    );
    expect(
      AppEditorialSurfaces.ingredientAccent(colors, 3),
      colors.inversePrimary,
    );
    expect(
      AppEditorialSurfaces.ingredientAccent(colors, 4),
      colors.primary,
    );
  });

  test('lifted card decoration uses default surface and requested shape', () {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final borderRadius = BorderRadius.circular(12);

    final decoration = AppEditorialSurfaces.liftedCardDecoration(
      colors,
      borderRadius: borderRadius,
      blurRadius: 18,
      shadowOffset: const Offset(0, 8),
    );

    expect(decoration.color, AppEditorialSurfaces.liftedCard(colors));
    expect(decoration.borderRadius, borderRadius);
    expect(
      (decoration.border as Border?)?.top.color,
      AppEditorialSurfaces.solidCardBorder(colors),
    );
    expect(decoration.boxShadow?.single.blurRadius, 18);
    expect(decoration.boxShadow?.single.offset, const Offset(0, 8));
  });

  test('soul gradient builds light and dark primary gradients', () {
    final light = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final dark = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    final lightGradient = AppEditorialSurfaces.soulGradient(light);
    final darkGradient = AppEditorialSurfaces.soulGradient(dark);

    expect(lightGradient.colors, hasLength(2));
    expect(darkGradient.colors, hasLength(2));
    expect(lightGradient.transform, const GradientRotation(0.45));
    expect(darkGradient.transform, const GradientRotation(0.45));
  });
}
