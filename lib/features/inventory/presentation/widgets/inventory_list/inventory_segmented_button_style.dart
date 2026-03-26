import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

ButtonStyle inventorySegmentedButtonStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    ),
    textStyle: WidgetStatePropertyAll(
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return BorderSide.none;
      }
      return BorderSide(
        color: AppInventoryEditorialSurfaces.ghostBorder(colors),
      );
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.surfaceBright;
      }
      return colors.surfaceContainerLow;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colors.onSurface;
      }
      return colors.onSurfaceVariant;
    }),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
  );
}
