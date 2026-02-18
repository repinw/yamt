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

    return ThemeData(
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
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
}
