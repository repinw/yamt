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
    required this.onQuickShoppingListActionPressed,
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

  /// The on quick shopping list action pressed.
  final VoidCallback? onQuickShoppingListActionPressed;

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
          : _InventoryItemPrimaryActions(
              viewData: viewData,
              onPrimaryActionPressed: onPrimaryActionPressed,
              onQuickShoppingListActionPressed:
                  onQuickShoppingListActionPressed,
            ),
      showSelectionCheckbox: showSelectionCheckbox,
      isSelected: isSelected,
      showExpandIndicator: !showSelectionCheckbox,
      isExpanded: isExpanded,
      expandIndicatorKey: expandIndicatorKey,
    );
  }
}

class _InventoryItemPrimaryActions extends StatelessWidget {
  const _InventoryItemPrimaryActions({
    required this.viewData,
    required this.onPrimaryActionPressed,
    required this.onQuickShoppingListActionPressed,
  });

  final InventoryItemRowViewData viewData;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback? onQuickShoppingListActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewData.showQuickShoppingListAction) ...[
          _InventoryItemQuickShoppingListAction(
            viewData: viewData,
            onPressed: onQuickShoppingListActionPressed,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        _InventoryItemPrimaryActionButton(
          viewData: viewData,
          onPrimaryActionPressed: onPrimaryActionPressed,
        ),
      ],
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
    final buttonWidth = viewData.isShoppingListPrimaryAction
        ? InventoryItemRowConstants.primaryActionWideWidth
        : InventoryItemRowConstants.primaryActionWidth;

    return InventoryPrimaryActionButton(
      tooltip: viewData.primaryActionTooltip,
      onPressed: onPrimaryActionPressed,
      showText: true,
      label: viewData.primaryActionLabel,
      width: buttonWidth,
      height: InventoryItemRowConstants.primaryActionHeight,
      enabledBackgroundColor: viewData.isShoppingListPrimaryAction
          ? viewData.eatActionBackgroundColor
          : colors.primary,
      disabledBackgroundColor: viewData.disabledActionBackgroundColor,
      enabledBorderColor: viewData.isShoppingListPrimaryAction
          ? viewData.eatActionBorderColor
          : colors.primary,
      disabledBorderColor: viewData.disabledActionBorderColor,
      enabledForegroundColor: viewData.isShoppingListPrimaryAction
          ? viewData.eatActionIconColor
          : colors.onPrimary,
      disabledForegroundColor: viewData.disabledActionIconColor,
      useGradientWhenShowText: false,
      icon: viewData.primaryActionIcon,
      showIconWithText: viewData.showPrimaryActionIconWithText,
    );
  }
}

class _InventoryItemQuickShoppingListAction extends StatelessWidget {
  const _InventoryItemQuickShoppingListAction({
    required this.viewData,
    required this.onPressed,
  });

  final InventoryItemRowViewData viewData;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = viewData.isQuickShoppingListActionEnabled
        ? onPressed
        : null;

    return InventoryPrimaryActionButton(
      tooltip: viewData.quickShoppingListActionTooltip,
      onPressed: effectiveOnPressed,
      showText: false,
      label: viewData.primaryActionLabel,
      width: InventoryItemRowConstants.shoppingListQuickActionSize,
      height: InventoryItemRowConstants.shoppingListQuickActionSize,
      enabledBackgroundColor: viewData.quickShoppingListActionBackgroundColor,
      disabledBackgroundColor: viewData.disabledActionBackgroundColor,
      enabledBorderColor: viewData.quickShoppingListActionBorderColor,
      disabledBorderColor: viewData.disabledActionBorderColor,
      enabledForegroundColor: viewData.quickShoppingListActionIconColor,
      disabledForegroundColor: viewData.disabledActionIconColor,
      useGradientWhenShowText: false,
      icon: viewData.quickShoppingListActionIcon,
    );
  }
}
