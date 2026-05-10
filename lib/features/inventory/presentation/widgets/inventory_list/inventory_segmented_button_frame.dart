import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Defines inventory segmented button frame.
class InventorySegmentedButtonFrame extends StatelessWidget {
  /// The inventory segmented button frame.
  const InventorySegmentedButtonFrame({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xs),
  });

  /// The child.
  final Widget child;

  /// The padding.
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
