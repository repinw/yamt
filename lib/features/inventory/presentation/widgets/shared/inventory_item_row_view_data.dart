import 'package:material_ui/material_ui.dart';

/// Display values of an inventory item row.
class InventoryItemRowViewData {
  /// Creates the row view data.
  const new({
    required this.nameTextStyle,
    required this.hasBrand,
    required this.brand,
    required this.remainingRatio,
    required this.remainingLabel,
    required this.segmentedByUnits,
  });

  /// The name text style.
  final TextStyle? nameTextStyle;

  /// Whether brand.
  final bool hasBrand;

  /// The brand.
  final String brand;

  /// The remaining ratio.
  final double remainingRatio;

  /// The remaining label.
  final String remainingLabel;

  /// The segmented by units.
  final bool segmentedByUnits;
}

/// Defines inventory nutrition metric.
class InventoryNutritionMetric {
  /// The inventory nutrition metric.
  const new({required this.label, required this.value});

  /// The label.
  final String label;

  /// The value.
  final String value;
}
