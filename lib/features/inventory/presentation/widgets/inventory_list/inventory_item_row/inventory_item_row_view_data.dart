import 'package:flutter/material.dart';

class InventoryItemRowViewData {
  const InventoryItemRowViewData({
    required this.rowBorderColor,
    required this.expandHintColor,
    required this.unitPriceLabel,
    required this.nameTextStyle,
    required this.hasBrand,
    required this.brand,
    required this.statusText,
    required this.statusColor,
    required this.remainingRatio,
    required this.remainingLabel,
    required this.hasWeight,
    required this.isPrimaryActionEnabled,
    required this.eatActionBackgroundColor,
    required this.disabledActionBackgroundColor,
    required this.eatActionBorderColor,
    required this.disabledActionBorderColor,
    required this.primaryActionTooltip,
    required this.primaryActionIcon,
    required this.eatActionIconColor,
    required this.disabledActionIconColor,
  });

  final Color rowBorderColor;
  final Color expandHintColor;
  final String unitPriceLabel;
  final TextStyle nameTextStyle;
  final bool hasBrand;
  final String brand;
  final String? statusText;
  final Color? statusColor;
  final double remainingRatio;
  final String remainingLabel;
  final bool hasWeight;
  final bool isPrimaryActionEnabled;
  final Color eatActionBackgroundColor;
  final Color disabledActionBackgroundColor;
  final Color eatActionBorderColor;
  final Color disabledActionBorderColor;
  final String primaryActionTooltip;
  final IconData primaryActionIcon;
  final Color eatActionIconColor;
  final Color disabledActionIconColor;
}
