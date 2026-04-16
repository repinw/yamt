import 'package:flutter/material.dart';

/// Defines inventory item row view data.
class InventoryItemRowViewData {
  /// The inventory item row view data.
  const InventoryItemRowViewData({
    required this.rowBorderColor,
    required this.expandedRowBorderColor,
    required this.unitPriceLabel,
    required this.nameTextStyle,
    required this.hasBrand,
    required this.brand,
    required this.statusText,
    required this.statusColor,
    required this.remainingRatio,
    required this.remainingLabel,
    required this.segmentedByUnits,
    required this.isPrimaryActionEnabled,
    required this.isBuyAgainPrimaryAction,
    required this.showPrimaryActionText,
    required this.primaryActionLabel,
    required this.eatActionBackgroundColor,
    required this.disabledActionBackgroundColor,
    required this.eatActionBorderColor,
    required this.disabledActionBorderColor,
    required this.primaryActionTooltip,
    required this.primaryActionIcon,
    required this.eatActionIconColor,
    required this.disabledActionIconColor,
    required this.nutritionMetrics,
  });

  /// The row border color.
  final Color rowBorderColor;

  /// The expanded row border color.
  final Color expandedRowBorderColor;

  /// The unit price label.
  final String unitPriceLabel;

  /// The name text style.
  final TextStyle nameTextStyle;

  /// Whether brand.
  final bool hasBrand;

  /// The brand.
  final String brand;

  /// The status text.
  final String? statusText;

  /// The status color.
  final Color? statusColor;

  /// The remaining ratio.
  final double remainingRatio;

  /// The remaining label.
  final String remainingLabel;

  /// The segmented by units.
  final bool segmentedByUnits;

  /// Whether primary action enabled.
  final bool isPrimaryActionEnabled;

  /// Whether buy again primary action.
  final bool isBuyAgainPrimaryAction;

  /// The show primary action text.
  final bool showPrimaryActionText;

  /// The primary action label.
  final String primaryActionLabel;

  /// The eat action background color.
  final Color eatActionBackgroundColor;

  /// The disabled action background color.
  final Color disabledActionBackgroundColor;

  /// The eat action border color.
  final Color eatActionBorderColor;

  /// The disabled action border color.
  final Color disabledActionBorderColor;

  /// The primary action tooltip.
  final String primaryActionTooltip;

  /// The primary action icon.
  final IconData primaryActionIcon;

  /// The eat action icon color.
  final Color eatActionIconColor;

  /// The disabled action icon color.
  final Color disabledActionIconColor;

  /// The nutrition metrics.
  final List<InventoryNutritionMetric> nutritionMetrics;
}

/// Defines inventory nutrition metric.
class InventoryNutritionMetric {
  /// The inventory nutrition metric.
  const InventoryNutritionMetric({required this.label, required this.value});

  /// The label.
  final String label;

  /// The value.
  final String value;
}
