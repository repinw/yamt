import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Shared leading icon.
class InventoryEatFlowLeadingIcon extends StatelessWidget {
  /// Creates leading icon.
  const InventoryEatFlowLeadingIcon({required this.icon, super.key});

  /// Icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, color: colors.primary, size: 18),
      ),
    );
  }
}
