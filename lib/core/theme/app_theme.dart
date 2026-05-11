import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_layout_tokens.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Centralized app themes generated from a single seed color.
abstract final class AppTheme {
  /// Builds light app theme for given seed color.
  static ThemeData light({required Color seedColor}) =>
      _buildTheme(Brightness.light, seedColor: seedColor);

  /// Builds dark app theme for given seed color.
  static ThemeData dark({required Color seedColor}) =>
      _buildTheme(Brightness.dark, seedColor: seedColor);

  static ThemeData _buildTheme(
    Brightness brightness, {
    required Color seedColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final canvasColor = _canvasColor(colorScheme);
    final cardColor = _cardColor(colorScheme);
    final cardBorderColor = _cardBorderColor(colorScheme);
    final textTheme = _buildTextTheme(
      brightness: brightness,
      colorScheme: colorScheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: canvasColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.lg),
          side: BorderSide(color: cardBorderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemeSpacing.xl,
            vertical: AppThemeSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeRadius.xl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemeSpacing.xl,
            vertical: AppThemeSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          side: BorderSide(
            color: AppInventoryEditorialSurfaces.ghostBorder(colorScheme),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeRadius.xl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.md),
        ),
      ),
    );
  }

  static Color _canvasColor(ColorScheme colorScheme) {
    final tintAlpha = colorScheme.brightness == Brightness.dark
        ? AppThemeBackground.darkTintAlpha
        : AppThemeBackground.lightTintAlpha;

    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: tintAlpha),
      colorScheme.surface,
    );
  }

  static Color _cardColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.surfaceContainerHigh;
    }
    return colorScheme.surfaceContainerLow;
  }

  static Color _cardBorderColor(ColorScheme colorScheme) {
    final alpha = colorScheme.brightness == Brightness.light
        ? AppThemeBackground.lightCardBorderAlpha
        : AppThemeBackground.darkCardBorderAlpha;
    return colorScheme.outlineVariant.withValues(alpha: alpha);
  }

  static TextTheme _buildTextTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final baseTextTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;

    return baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        height: 0.92,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.02,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
