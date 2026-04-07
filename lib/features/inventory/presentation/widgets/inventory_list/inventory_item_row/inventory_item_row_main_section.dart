import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/brand_badge.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/category_icon.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_primary_action_button.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/remaining_progress_bar.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/status_line.dart';

class InventoryItemRowMainSection extends StatelessWidget {
  const InventoryItemRowMainSection({
    super.key,
    required this.item,
    required this.viewData,
    required this.isExpanded,
    required this.onPrimaryActionPressed,
    required this.showSelectionCheckbox,
    required this.isSelected,
  });

  final InventoryItemRowSnapshot item;
  final InventoryItemRowViewData viewData;
  final bool isExpanded;
  final VoidCallback? onPrimaryActionPressed;
  final bool showSelectionCheckbox;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showSelectionCheckbox) ...[
          IgnorePointer(
            child: Checkbox(
              value: isSelected,
              onChanged: (_) {},
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        CategoryIcon(
          name: item.category ?? item.name,
          barcode: item.barcode,
          imageUrl: item.imageUrl,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _InventoryItemRowInfoColumn(item: item, viewData: viewData),
        ),
        if (!showSelectionCheckbox) ...[
          const SizedBox(width: AppSpacing.sm),
          InventoryExpandIndicator(
            isExpanded: isExpanded,
            rotationKey: Key(
              'inventory_item_row_expand_indicator_${item.itemId}',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _InventoryItemPrimaryActionButton(
            viewData: viewData,
            onPrimaryActionPressed: onPrimaryActionPressed,
          ),
        ],
      ],
    );
  }
}

class _InventoryItemRowInfoColumn extends StatelessWidget {
  const _InventoryItemRowInfoColumn({
    required this.item,
    required this.viewData,
  });

  final InventoryItemRowSnapshot item;
  final InventoryItemRowViewData viewData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewData.hasBrand) ...[
          BrandBadge(brand: viewData.brand),
          const SizedBox(height: AppSpacing.xxs),
        ],
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: viewData.nameTextStyle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (viewData.statusText != null && viewData.statusColor != null)
          StatusLine(text: viewData.statusText!, color: viewData.statusColor!),
        const SizedBox(height: AppSpacing.xs),
        RemainingProgressBar(
          ratio: viewData.remainingRatio,
          stockLabel: viewData.remainingLabel,
          segmentedByUnits: viewData.segmentedByUnits,
          totalUnits: item.initialQuantity,
          remainingUnits: item.quantity,
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
    final buttonWidth = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionWidth
        : AppInventoryEditorial.actionTileSize;
    final buttonHeight = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionHeight
        : AppInventoryEditorial.actionTileSize;

    return InventoryPrimaryActionButton(
      tooltip: viewData.primaryActionTooltip,
      onPressed: onPrimaryActionPressed,
      showText: viewData.showPrimaryActionText,
      label: viewData.primaryActionLabel,
      width: buttonWidth,
      height: buttonHeight,
      enabledBackgroundColor: viewData.eatActionBackgroundColor,
      disabledBackgroundColor: viewData.disabledActionBackgroundColor,
      enabledBorderColor: viewData.eatActionBorderColor,
      disabledBorderColor: viewData.disabledActionBorderColor,
      enabledForegroundColor: viewData.eatActionIconColor,
      disabledForegroundColor: viewData.disabledActionIconColor,
      icon: viewData.primaryActionIcon,
      iconSize: InventoryItemRowConstants.actionIconSize,
    );
  }
}
