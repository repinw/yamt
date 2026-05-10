import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

void main() {
  test('editorial surfaces derive colors from scheme tokens', () {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.seed);

    expect(
      AppInventoryEditorialSurfaces.liftedCard(colors),
      colors.surfaceContainerLowest,
    );
    expect(
      AppInventoryEditorialSurfaces.section(colors),
      colors.surfaceContainerLow,
    );
    expect(
      AppInventoryEditorialSurfaces.glass(colors),
      colors.surfaceContainerLow.withValues(
        alpha: AppInventoryEditorial.glassOpacity,
      ),
    );
  });

  test('ingredient accents use color scheme roles and cycle', () {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.seed);

    expect(
      AppInventoryEditorialSurfaces.ingredientAccent(colors, 0),
      colors.primary,
    );
    expect(
      AppInventoryEditorialSurfaces.ingredientAccent(colors, 1),
      colors.secondary,
    );
    expect(
      AppInventoryEditorialSurfaces.ingredientAccent(colors, 2),
      colors.tertiary,
    );
    expect(
      AppInventoryEditorialSurfaces.ingredientAccent(colors, 3),
      colors.inversePrimary,
    );
    expect(
      AppInventoryEditorialSurfaces.ingredientAccent(colors, 4),
      colors.primary,
    );
  });

  test('lifted card decoration uses default surface and requested shape', () {
    final colors = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final borderRadius = BorderRadius.circular(12);

    final decoration = AppInventoryEditorialSurfaces.liftedCardDecoration(
      colors,
      borderRadius: borderRadius,
      blurRadius: 18,
      shadowOffset: const Offset(0, 8),
    );

    expect(decoration.color, colors.surfaceContainerLowest);
    expect(decoration.borderRadius, borderRadius);
    expect(decoration.boxShadow?.single.blurRadius, 18);
    expect(decoration.boxShadow?.single.offset, const Offset(0, 8));
  });

  test('soul gradient builds light and dark primary gradients', () {
    final light = ColorScheme.fromSeed(seedColor: AppColors.seed);
    final dark = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );

    final lightGradient = AppInventoryEditorialSurfaces.soulGradient(light);
    final darkGradient = AppInventoryEditorialSurfaces.soulGradient(dark);

    expect(lightGradient.colors, hasLength(2));
    expect(darkGradient.colors, hasLength(2));
    expect(lightGradient.transform, const GradientRotation(0.45));
    expect(darkGradient.transform, const GradientRotation(0.45));
  });
}
