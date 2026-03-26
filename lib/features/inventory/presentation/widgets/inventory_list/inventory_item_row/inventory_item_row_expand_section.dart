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
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.throwAwayLabel,
    required this.onDeletePressed,
    required this.onEditPressed,
    required this.onThrowAwayPressed,
    required this.onSwapCandidatePressed,
  });

  final bool isExpanded;
  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String deleteLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final String throwAwayLabel;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;
  final VoidCallback? onThrowAwayPressed;
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
                deleteLabel: deleteLabel,
                editLabel: editLabel,
                swapCandidateLabel: swapCandidateLabel,
                throwAwayLabel: throwAwayLabel,
                onDeletePressed: onDeletePressed,
                onEditPressed: onEditPressed,
                onThrowAwayPressed: onThrowAwayPressed,
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
    required this.deleteLabel,
    required this.editLabel,
    required this.swapCandidateLabel,
    required this.throwAwayLabel,
    required this.onDeletePressed,
    required this.onEditPressed,
    required this.onThrowAwayPressed,
    required this.onSwapCandidatePressed,
  });

  final InventoryItemRowViewData viewData;
  final ColorScheme colorScheme;
  final String deleteLabel;
  final String editLabel;
  final String swapCandidateLabel;
  final String throwAwayLabel;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;
  final VoidCallback? onThrowAwayPressed;
  final VoidCallback onSwapCandidatePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (viewData.nutritionMetrics.isNotEmpty) ...[
          _InventoryNutritionStrip(
            metrics: viewData.nutritionMetrics,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          children: [
            Expanded(
              child: _InventoryItemActionButton(
                label: throwAwayLabel,
                icon: Icons.delete_sweep_outlined,
                foregroundColor: colorScheme.onSurfaceVariant,
                backgroundColor: colorScheme.surfaceContainerHigh,
                onPressed: onThrowAwayPressed,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
                label: deleteLabel,
                icon: Icons.delete_outline_rounded,
                foregroundColor: colorScheme.error,
                backgroundColor: colorScheme.errorContainer.withValues(
                  alpha: 0.38,
                ),
                onPressed: onDeletePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InventoryNutritionStrip extends StatelessWidget {
  const _InventoryNutritionStrip({
    required this.metrics,
    required this.colorScheme,
  });

  final List<InventoryNutritionMetric> metrics;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final stripColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.04),
      colorScheme.surfaceContainerLowest,
    );

    return SizedBox(
      height: InventoryItemRowConstants.nutritionStripHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: stripColor,
          borderRadius: BorderRadius.circular(
            InventoryItemRowConstants.nutritionStripRadius,
          ),
          border: Border.all(
            color: AppInventoryEditorialSurfaces.ghostBorder(colorScheme),
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < metrics.length; index += 1) ...[
              Expanded(
                child: _InventoryNutritionMetricCell(
                  metric: metrics[index],
                  colorScheme: colorScheme,
                ),
              ),
              if (index < metrics.length - 1)
                SizedBox(
                  height: InventoryItemRowConstants.nutritionStripDividerHeight,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppInventoryEditorialSurfaces.ghostBorder(
                      colorScheme,
                    ).withValues(alpha: 0.9),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InventoryNutritionMetricCell extends StatelessWidget {
  const _InventoryNutritionMetricCell({
    required this.metric,
    required this.colorScheme,
  });

  final InventoryNutritionMetric metric;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
