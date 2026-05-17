import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';

/// Defines inventory item row expand section.
class InventoryItemRowExpandSection extends StatelessWidget {
  /// The inventory item row expand section.
  const InventoryItemRowExpandSection({
    required this.isExpanded,
    required this.viewData,
    required this.colorScheme,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.removeLabel,
    required this.onEditPressed,
    required this.onRemovePressed,
    required this.onSwapCandidatePressed,
    super.key,
  });

  /// Whether expanded.
  final bool isExpanded;

  /// The view data.
  final InventoryItemRowViewData viewData;

  /// The color scheme.
  final ColorScheme colorScheme;

  /// The edit label.
  final String editLabel;

  /// The swap candidate label.
  final String swapCandidateLabel;

  /// The remove label.
  final String removeLabel;

  /// The on edit pressed.
  final VoidCallback? onEditPressed;

  /// The on remove pressed.
  final VoidCallback? onRemovePressed;

  /// The on swap candidate pressed.
  final VoidCallback onSwapCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: InventoryItemRowConstants.expandPanelDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.only(
                top: InventoryItemRowConstants.actionPanelTopSpacing,
              ),
              child: _InventoryItemActionPanel(
                viewData: viewData,
                colorScheme: colorScheme,
                editLabel: editLabel,
                swapCandidateLabel: swapCandidateLabel,
                removeLabel: removeLabel,
                onEditPressed: onEditPressed,
                onRemovePressed: onRemovePressed,
                onSwapCandidatePressed: onSwapCandidatePressed,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _InventoryItemActionPanel extends StatelessWidget {
  const _InventoryItemActionPanel({
    required this.viewData,
    required this.colorScheme,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.removeLabel,
    required this.onEditPressed,
    required this.onRemovePressed,
    required this.onSwapCandidatePressed,
  });

  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String editLabel;
  final String swapCandidateLabel;
  final String removeLabel;
  final VoidCallback? onEditPressed;
  final VoidCallback? onRemovePressed;
  final VoidCallback onSwapCandidatePressed;

  @override
  Widget build(BuildContext context) {
    final warningActionColors = _warningActionColors(colorScheme);

    return Column(
      children: [
        if (viewData.nutritionMetrics.isNotEmpty) ...[
          InventoryNutritionStrip(
            metrics: viewData.nutritionMetrics,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          children: [
            Expanded(
              child: _InventoryItemActionButton(
                label: editLabel,
                icon: Icons.edit_outlined,
                foregroundColor: colorScheme.onSurfaceVariant,
                backgroundColor: colorScheme.surfaceContainerHigh,
                onPressed: onEditPressed,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _InventoryItemActionButton(
                label: swapCandidateLabel,
                icon: Icons.swap_horiz_rounded,
                foregroundColor: colorScheme.onSurfaceVariant,
                backgroundColor: colorScheme.surfaceContainerHigh,
                onPressed: onSwapCandidatePressed,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _InventoryItemActionButton(
                label: removeLabel,
                icon: Icons.delete_outline_rounded,
                foregroundColor: warningActionColors.iconColor,
                backgroundColor: warningActionColors.backgroundColor,
                onPressed: onRemovePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _InventoryItemActionColors _warningActionColors(ColorScheme colors) {
    const tint = AppEditorial.warning;

    return _InventoryItemActionColors(
      backgroundColor: Color.alphaBlend(
        tint.withValues(alpha: 0.22),
        colors.primaryContainer,
      ),
      iconColor: Color.alphaBlend(
        tint.withValues(alpha: 0.82),
        colors.onPrimaryContainer,
      ),
    );
  }
}

class _InventoryItemActionButton extends StatelessWidget {
  const _InventoryItemActionButton({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: InventoryItemRowConstants.actionButtonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: InventoryItemRowConstants.actionButtonIconSize),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemActionColors {
  const _InventoryItemActionColors({
    required this.backgroundColor,
    required this.iconColor,
  });

  final Color backgroundColor;
  final Color iconColor;
}
