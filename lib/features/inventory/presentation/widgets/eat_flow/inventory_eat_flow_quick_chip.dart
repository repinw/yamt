import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared quick chip.
class InventoryEatFlowQuickChip extends StatelessWidget {
  /// Creates quick chip.
  const InventoryEatFlowQuickChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    super.key,
  });

  /// Label.
  final String label;

  /// Whether selected.
  final bool isSelected;

  /// Press callback.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: false,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
