import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Divider used between sections in inventory filter sheets.
class InventoryFilterDivider extends StatelessWidget {
  /// Creates inventory filter divider.
  const InventoryFilterDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
  }
}
