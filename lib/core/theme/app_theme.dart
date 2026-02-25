import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Centralized app themes generated from a single seed color.
abstract final class AppTheme {
  static ThemeData light({required Color seedColor}) =>
      _buildTheme(Brightness.light, seedColor: seedColor);

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
    final scaffoldBackground = _scaffoldBackground(colorScheme);

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  static Color _scaffoldBackground(ColorScheme colorScheme) {
    final tintAlpha = colorScheme.brightness == Brightness.dark
        ? AppThemeBackground.darkTintAlpha
        : AppThemeBackground.lightTintAlpha;

    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: tintAlpha),
      colorScheme.surface,
    );
  }
}
