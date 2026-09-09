import 'package:flutter/material.dart';

/// Centralized app themes for light and dark modes.
abstract final class AppTheme {
  /// Builds standard light Material 3 theme.
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  /// Builds standard dark Material 3 theme.
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );
}
