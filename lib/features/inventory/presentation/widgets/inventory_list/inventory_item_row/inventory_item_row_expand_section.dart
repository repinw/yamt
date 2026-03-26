import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';

class InventoryItemRowExpandSection extends StatelessWidget {
  const InventoryItemRowExpandSection({
    super.key,
    required this.isExpanded,
    required this.viewData,
    required this.colorScheme,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onDeletePressed,
    required this.onThrowAwayPressed,
    required this.onToggleExpanded,
    required this.retryBarcodeLabel,
    required this.onRetryBarcodePressed,
  });

  final bool isExpanded;
  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onDeletePressed;
  final VoidCallback? onThrowAwayPressed;
  final VoidCallback onToggleExpanded;
  final String retryBarcodeLabel;
  final VoidCallback? onRetryBarcodePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: InventoryItemRowConstants.expandSectionTopSpacing,
        ),
        InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(
            InventoryItemRowConstants.expandToggleRadius,
          ),
          child: AnimatedContainer(
            duration: InventoryItemRowConstants.expandArrowDuration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isExpanded
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(
                InventoryItemRowConstants.expandToggleRadius,
              ),
              border: Border.all(
                color: AppInventoryEditorialSurfaces.ghostBorder(colorScheme),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: viewData.expandHintColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(
                      InventoryItemRowConstants.expandToggleRadius,
                    ),
                  ),
                  child: const SizedBox(width: 18, height: 4),
                ),
                const SizedBox(width: AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: isExpanded ? math.pi : 0),
                  duration: InventoryItemRowConstants.expandArrowDuration,
                  curve: Curves.easeOutCubic,
                  child: Transform.scale(
                    scaleX: InventoryItemRowConstants.expandArrowScaleX,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: InventoryItemRowConstants.expandArrowSize,
                      color: viewData.expandHintColor,
                    ),
                  ),
                  builder: (context, angle, child) {
                    return Transform.rotate(angle: angle, child: child);
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
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
                    deleteLabel: deleteLabel,
                    throwAwayLabel: throwAwayLabel,
                    onDeletePressed: onDeletePressed,
                    onThrowAwayPressed: onThrowAwayPressed,
                    retryBarcodeLabel: retryBarcodeLabel,
                    onRetryBarcodePressed: onRetryBarcodePressed,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _InventoryItemActionPanel extends StatelessWidget {
  const _InventoryItemActionPanel({
    required this.viewData,
    required this.colorScheme,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onDeletePressed,
    required this.onThrowAwayPressed,
    required this.retryBarcodeLabel,
    required this.onRetryBarcodePressed,
  });

  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onDeletePressed;
  final VoidCallback? onThrowAwayPressed;
  final String retryBarcodeLabel;
  final VoidCallback? onRetryBarcodePressed;

  @override
  Widget build(BuildContext context) {
    final actionShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppInventoryEditorialSurfaces.section(colorScheme),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppInventoryEditorialSurfaces.ghostBorder(colorScheme),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewData.unitPriceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: InventoryItemRowConstants.actionContentSpacing,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDeletePressed,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: InventoryItemRowConstants.actionButtonIconSize,
                        ),
                        label: Text(deleteLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          backgroundColor: colorScheme.errorContainer
                              .withValues(alpha: 0.22),
                          side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.18),
                          ),
                          minimumSize: const Size(
                            0,
                            InventoryItemRowConstants.actionButtonHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: actionShape,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: InventoryItemRowConstants.actionButtonSpacing,
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onThrowAwayPressed,
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          size: InventoryItemRowConstants.actionButtonIconSize,
                        ),
                        label: Text(throwAwayLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.tertiaryContainer,
                          foregroundColor: colorScheme.onTertiaryContainer,
                          minimumSize: const Size(
                            0,
                            InventoryItemRowConstants.actionButtonHeight,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: actionShape,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onRetryBarcodePressed != null) ...[
                  const SizedBox(
                    height: InventoryItemRowConstants.actionContentSpacing,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRetryBarcodePressed,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: InventoryItemRowConstants.actionButtonIconSize,
                      ),
                      label: Text(retryBarcodeLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: AppInventoryEditorialSurfaces.ghostBorder(
                            colorScheme,
                          ),
                        ),
                        minimumSize: const Size(
                          0,
                          InventoryItemRowConstants.actionButtonHeight,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: actionShape,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
