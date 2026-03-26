import 'package:flutter/material.dart';

class InventoryItemRowViewData {
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

  final Color rowBorderColor;
  final Color expandedRowBorderColor;
  final String unitPriceLabel;
  final TextStyle nameTextStyle;
  final bool hasBrand;
  final String brand;
  final String? statusText;
  final Color? statusColor;
  final double remainingRatio;
  final String remainingLabel;
  final bool segmentedByUnits;
  final bool isPrimaryActionEnabled;
  final bool isBuyAgainPrimaryAction;
  final bool showPrimaryActionText;
  final String primaryActionLabel;
  final Color eatActionBackgroundColor;
  final Color disabledActionBackgroundColor;
  final Color eatActionBorderColor;
  final Color disabledActionBorderColor;
  final String primaryActionTooltip;
  final IconData primaryActionIcon;
  final Color eatActionIconColor;
  final Color disabledActionIconColor;
  final List<InventoryNutritionMetric> nutritionMetrics;
}

class InventoryNutritionMetric {
  const InventoryNutritionMetric({required this.label, required this.value});

  final String label;
  final String value;
}
