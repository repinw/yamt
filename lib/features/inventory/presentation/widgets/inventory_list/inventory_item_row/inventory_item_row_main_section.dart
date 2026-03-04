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
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/remaining_progress_bar.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/status_line.dart';

class InventoryItemRowMainSection extends StatelessWidget {
  const InventoryItemRowMainSection({
    super.key,
    required this.item,
    required this.viewData,
    required this.onPrimaryActionPressed,
  });

  final InventoryItemRowSnapshot item;
  final InventoryItemRowViewData viewData;
  final VoidCallback? onPrimaryActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CategoryIcon(name: item.category ?? item.name, barcode: item.barcode),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _InventoryItemRowInfoColumn(item: item, viewData: viewData),
        ),
        const SizedBox(width: AppSpacing.md),
        _InventoryItemPrimaryActionButton(
          viewData: viewData,
          onPrimaryActionPressed: onPrimaryActionPressed,
        ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: viewData.nameTextStyle,
              ),
            ),
          ],
        ),
        if (viewData.hasBrand) ...[
          const SizedBox(height: AppSpacing.xxs),
          BrandBadge(brand: viewData.brand),
        ],
        const SizedBox(height: AppSpacing.xxs * 2),
        if (viewData.statusText != null && viewData.statusColor != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: StatusLine(
              text: viewData.statusText!,
              color: viewData.statusColor!,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: viewData.isPrimaryActionEnabled
            ? viewData.eatActionBackgroundColor
            : viewData.disabledActionBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: viewData.isPrimaryActionEnabled
              ? viewData.eatActionBorderColor
              : viewData.disabledActionBorderColor,
        ),
      ),
      child: SizedBox.square(
        dimension: AppSizes.dialogIconContainer,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          splashRadius: AppSpacing.xxl,
          tooltip: viewData.primaryActionTooltip,
          onPressed: onPrimaryActionPressed,
          icon: Icon(
            viewData.primaryActionIcon,
            size: InventoryItemRowConstants.actionIconSize,
          ),
          color: viewData.isPrimaryActionEnabled
              ? viewData.eatActionIconColor
              : viewData.disabledActionIconColor,
        ),
      ),
    );
  }
}
