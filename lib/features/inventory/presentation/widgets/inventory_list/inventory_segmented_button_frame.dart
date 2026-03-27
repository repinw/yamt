import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class InventorySegmentedButtonFrame extends StatelessWidget {
  const InventorySegmentedButtonFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xs),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
