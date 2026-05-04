import 'package:flutter/material.dart';

/// Defines inventory item row view data.
class InventoryItemRowViewData {
  /// The inventory item row view data.
  const InventoryItemRowViewData({
    required this.rowBorderColor,
    required this.expandedRowBorderColor,
    required this.nameTextStyle,
    required this.hasBrand,
    required this.brand,
    required this.remainingRatio,
    required this.remainingLabel,
    required this.segmentedByUnits,
    required this.isShoppingListPrimaryAction,
    required this.showPrimaryActionIconWithText,
    required this.primaryActionLabel,
    required this.eatActionBackgroundColor,
    required this.disabledActionBackgroundColor,
    required this.eatActionBorderColor,
    required this.disabledActionBorderColor,
    required this.primaryActionTooltip,
    required this.primaryActionIcon,
    required this.eatActionIconColor,
    required this.disabledActionIconColor,
    required this.showQuickShoppingListAction,
    required this.isQuickShoppingListActionEnabled,
    required this.quickShoppingListActionTooltip,
    required this.quickShoppingListActionIcon,
    required this.quickShoppingListActionBackgroundColor,
    required this.quickShoppingListActionBorderColor,
    required this.quickShoppingListActionIconColor,
    required this.nutritionMetrics,
  });

  /// The row border color.
  final Color rowBorderColor;

  /// The expanded row border color.
  final Color expandedRowBorderColor;

  /// The name text style.
  final TextStyle nameTextStyle;

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

  /// Whether the shopping list action is the primary action.
  final bool isShoppingListPrimaryAction;

  /// Whether the primary action keeps its icon next to the label.
  final bool showPrimaryActionIconWithText;

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

  /// Whether to show the shopping list quick action.
  final bool showQuickShoppingListAction;

  /// Whether the shopping list quick action is enabled.
  final bool isQuickShoppingListActionEnabled;

  /// The shopping list quick action tooltip.
  final String quickShoppingListActionTooltip;

  /// The shopping list quick action icon.
  final IconData quickShoppingListActionIcon;

  /// The shopping list quick action background color.
  final Color quickShoppingListActionBackgroundColor;

  /// The shopping list quick action border color.
  final Color quickShoppingListActionBorderColor;

  /// The shopping list quick action icon color.
  final Color quickShoppingListActionIconColor;

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
