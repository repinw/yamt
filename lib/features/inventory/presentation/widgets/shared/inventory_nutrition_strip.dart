import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_item_row_view_data.dart';

export 'package:yamt/features/inventory/presentation/formatters/'
    'inventory_nutrition_format.dart'
    show formatInventoryNutritionValue;

/// Defines inventory nutrition strip.
class InventoryNutritionStrip extends StatelessWidget {
  /// The inventory nutrition strip.
  const InventoryNutritionStrip({
    required this.metrics,
    required this.colorScheme,
    super.key,
  });

  /// The metrics.
  final List<InventoryNutritionMetric> metrics;

  /// The color scheme.
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return NutritionMetricsStrip(
      metrics: metrics
          .map(
            (metric) =>
                NutritionMetric(label: metric.label, value: metric.value),
          )
          .toList(growable: false),
      colorScheme: colorScheme,
    );
  }
}
