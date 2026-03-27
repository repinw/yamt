import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';

class InventoryNutritionStrip extends StatelessWidget {
  const InventoryNutritionStrip({
    super.key,
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

String formatInventoryNutritionValue(double value) {
  final hasFraction = value % 1 != 0;
  return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
}
