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
        CategoryIcon(
          name: item.category ?? item.name,
          barcode: item.barcode,
          imageUrl: item.imageUrl,
        ),
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
    final colors = Theme.of(context).colorScheme;
    final usesSoulGradient =
        viewData.isPrimaryActionEnabled && viewData.showPrimaryActionText;
    final backgroundColor = usesSoulGradient
        ? null
        : viewData.isPrimaryActionEnabled
        ? viewData.eatActionBackgroundColor
        : viewData.disabledActionBackgroundColor;
    final borderColor = usesSoulGradient
        ? Colors.transparent
        : viewData.isPrimaryActionEnabled
        ? viewData.eatActionBorderColor
        : viewData.disabledActionBorderColor;
    final foregroundColor = usesSoulGradient
        ? colors.onPrimary
        : viewData.isPrimaryActionEnabled
        ? viewData.eatActionIconColor
        : viewData.disabledActionIconColor;
    final buttonWidth = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionWidth
        : AppInventoryEditorial.actionTileSize;
    final buttonHeight = viewData.showPrimaryActionText
        ? InventoryItemRowConstants.primaryActionHeight
        : AppInventoryEditorial.actionTileSize;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: usesSoulGradient
            ? AppInventoryEditorialSurfaces.soulGradient(colors)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 24,
          ),
        ],
      ),
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          splashRadius: AppSpacing.xxl,
          tooltip: viewData.primaryActionTooltip,
          onPressed: onPrimaryActionPressed,
          icon: viewData.showPrimaryActionText
              ? Text(
                  viewData.primaryActionLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontSize: 12,
                  ),
                )
              : Icon(
                  viewData.primaryActionIcon,
                  size: InventoryItemRowConstants.actionIconSize,
                ),
          color: foregroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: viewData.showPrimaryActionText
                ? AppSpacing.sm
                : AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}
