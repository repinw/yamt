import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

abstract final class AppColors {
  static const Color seed = AppSeedColors.teal;
}

abstract final class AppSeedColors {
  static const Color lime = Color(0xFF29F006);
  static const Color blue = Color(0xFF0D47A1);
  static const Color teal = Color(0xFF00695C);
  static const Color pink = Color.fromARGB(255, 255, 0, 111);
  static const Color orange = Color(0xFFE65100);

  static const List<Color> values = <Color>[lime, blue, teal, pink, orange];
}

abstract final class AppThemeBackground {
  // Subtle light/dark tinting tuned against Material 3 surface tones.
  static const double lightTintAlpha = 0.04;
  static const double darkTintAlpha = 0.18;
  // Borders stay subtle in dark mode and clearer in light mode.
  static const double lightCardBorderAlpha = 0.28;
  static const double darkCardBorderAlpha = 0.18;
}

abstract final class AppInventoryEditorial {
  static const Color primary = Color(0xFF006941);
  static const Color primaryDim = Color(0xFF005C38);
  static const Color warning = Color(0xFFAB2D00);

  static const double ambientShadowAlpha = 0.06;
  static const double ghostBorderAlpha = 0.15;
  static const double glassOpacity = 0.8;
  static const double glassBlur = 20;

  static const double cardRadius = AppRadius.xl;
  static const double categoryTileSize = 56;
  static const double actionTileSize = 48;
  static const double progressHeight = 8;
}

abstract final class AppInventoryEditorialSurfaces {
  static Color liftedCard(ColorScheme colors) => colors.surfaceContainerLowest;

  static Color section(ColorScheme colors) => colors.surfaceContainerLow;

  static Color glass(ColorScheme colors) {
    return colors.surfaceContainerLow.withValues(
      alpha: AppInventoryEditorial.glassOpacity,
    );
  }

  static Color ghostBorder(ColorScheme colors) {
    return colors.outlineVariant.withValues(
      alpha: AppInventoryEditorial.ghostBorderAlpha,
    );
  }

  static Color ambientShadow(ColorScheme colors) {
    return colors.onSurface.withValues(
      alpha: AppInventoryEditorial.ambientShadowAlpha,
    );
  }

  static BoxShadow ambientBoxShadow(
    ColorScheme colors, {
    double blurRadius = 36,
    Offset offset = const Offset(0, 18),
  }) {
    return BoxShadow(
      color: ambientShadow(colors),
      blurRadius: blurRadius,
      offset: offset,
    );
  }

  static BoxDecoration liftedCardDecoration(
    ColorScheme colors, {
    required BorderRadiusGeometry borderRadius,
    Color? color,
    double blurRadius = 36,
    Offset shadowOffset = const Offset(0, 18),
  }) {
    return _layeredDecoration(
      colors: colors,
      color: color ?? liftedCard(colors),
      borderRadius: borderRadius,
      blurRadius: blurRadius,
      shadowOffset: shadowOffset,
    );
  }

  static BoxDecoration sectionCardDecoration(
    ColorScheme colors, {
    required BorderRadiusGeometry borderRadius,
    Color? color,
    double blurRadius = 36,
    Offset shadowOffset = const Offset(0, 18),
  }) {
    return _layeredDecoration(
      colors: colors,
      color: color ?? section(colors),
      borderRadius: borderRadius,
      blurRadius: blurRadius,
      shadowOffset: shadowOffset,
    );
  }

  static BoxDecoration glassCardDecoration(
    ColorScheme colors, {
    required BorderRadiusGeometry borderRadius,
    double blurRadius = 48,
    Offset shadowOffset = const Offset(0, 24),
  }) {
    return _layeredDecoration(
      colors: colors,
      color: glass(colors),
      borderRadius: borderRadius,
      blurRadius: blurRadius,
      shadowOffset: shadowOffset,
    );
  }

  static LinearGradient soulGradient(ColorScheme colors) {
    final start = Color.alphaBlend(
      AppInventoryEditorial.primary.withValues(alpha: 0.92),
      colors.primary,
    );
    final end = Color.alphaBlend(
      AppInventoryEditorial.primaryDim.withValues(alpha: 0.92),
      colors.primary,
    );

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
      transform: GradientRotation(0.45),
    );
  }

  static LinearGradient backdropGradient(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final startColor = Color.alphaBlend(
      AppInventoryEditorial.primary.withValues(alpha: isDark ? 0.2 : 0.12),
      colors.surface,
    );
    final middleColor = Color.alphaBlend(
      colors.surfaceContainerLowest.withValues(alpha: isDark ? 0.4 : 0.9),
      colors.surface,
    );
    final endColor = Color.alphaBlend(
      colors.outlineVariant.withValues(alpha: isDark ? 0.16 : 0.1),
      colors.surface,
    );

    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [startColor, middleColor, endColor],
      stops: const [0, 0.5, 1],
    );
  }

  static BoxDecoration _layeredDecoration({
    required ColorScheme colors,
    required Color color,
    required BorderRadiusGeometry borderRadius,
    required double blurRadius,
    required Offset shadowOffset,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: Border.all(color: ghostBorder(colors)),
      boxShadow: [
        ambientBoxShadow(colors, blurRadius: blurRadius, offset: shadowOffset),
      ],
    );
  }
}
