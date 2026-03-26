import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

ButtonStyle inventorySegmentedButtonStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    ),
    textStyle: WidgetStatePropertyAll(
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return BorderSide.none;
      }
      return BorderSide.none;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.surfaceContainerLowest;
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.primary;
      }
      return colors.onSurfaceVariant;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    elevation: const WidgetStatePropertyAll(0),
    overlayColor: WidgetStatePropertyAll(
      colors.surfaceContainerHigh.withValues(alpha: 0.16),
    ),
  );
}
