import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_tile_header_layout.dart';

/// Defines inventory item row main section.
class InventoryItemRowMainSection extends StatelessWidget {
  /// The inventory item row main section.
  const InventoryItemRowMainSection({
    required this.item,
    required this.viewData,
    required this.isExpanded,
    required this.onPrimaryActionPressed,
    required this.showSelectionCheckbox,
    required this.isSelected,
    super.key,
    this.expandIndicatorKey,
  });

  /// The item.
  final InventoryItemRowSnapshot item;

  /// The view data.
  final InventoryItemRowViewData viewData;

  /// Whether expanded.
  final bool isExpanded;

  /// The on primary action pressed.
  final VoidCallback? onPrimaryActionPressed;

  /// The show selection checkbox.
  final bool showSelectionCheckbox;

  /// Whether selected.
  final bool isSelected;

  /// The expand indicator key.
  final Key? expandIndicatorKey;

  @override
  Widget build(BuildContext context) {
    return InventoryTileHeaderLayout(
      leading: InventoryItemImageTile(imageUrl: item.imageUrl),
      badgeText: viewData.hasBrand ? viewData.brand : null,
      title: item.name,
      titleStyle: viewData.nameTextStyle,
      statusText: viewData.statusText,
      statusColor: viewData.statusColor,
      progressRatio: viewData.remainingRatio,
      progressLabel: viewData.remainingLabel,
      segmentedByUnits: viewData.segmentedByUnits,
      totalUnits: item.initialQuantity,
      remainingUnits: item.quantity,
      action: showSelectionCheckbox
          ? null
          : _InventoryItemPrimaryActionButton(
              viewData: viewData,
              onPrimaryActionPressed: onPrimaryActionPressed,
            ),
      showSelectionCheckbox: showSelectionCheckbox,
      isSelected: isSelected,
      showExpandIndicator: !showSelectionCheckbox,
      isExpanded: isExpanded,
      expandIndicatorKey: expandIndicatorKey,
    );
  }
}

class _InventoryItemPrimaryActionButton extends StatelessWidget {
  const _InventoryItemPrimaryActionButton({
    required this.viewData,
    required this.onPrimaryActionPressed,
  });

  final InventoryItemRowViewData viewData;
  final VoidCallback? onPrimaryActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buttonWidth = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionWidth
        : AppInventoryEditorial.actionTileSize;
    final buttonHeight = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionHeight
        : AppInventoryEditorial.actionTileSize;
    final solidTextButton = viewData.showPrimaryActionText;
    final enabledBackgroundColor = solidTextButton
        ? colors.primary
        : viewData.eatActionBackgroundColor;
    final enabledBorderColor = solidTextButton
        ? colors.primary
        : viewData.eatActionBorderColor;
    final enabledForegroundColor = solidTextButton
        ? colors.onPrimary
        : viewData.eatActionIconColor;

    return InventoryPrimaryActionButton(
      tooltip: viewData.primaryActionTooltip,
      onPressed: onPrimaryActionPressed,
      showText: viewData.showPrimaryActionText,
      label: viewData.primaryActionLabel,
      width: buttonWidth,
      height: buttonHeight,
      enabledBackgroundColor: enabledBackgroundColor,
      disabledBackgroundColor: viewData.disabledActionBackgroundColor,
      enabledBorderColor: enabledBorderColor,
      disabledBorderColor: viewData.disabledActionBorderColor,
      enabledForegroundColor: enabledForegroundColor,
      disabledForegroundColor: viewData.disabledActionIconColor,
      useGradientWhenShowText: false,
      icon: viewData.primaryActionIcon,
    );
  }
}
