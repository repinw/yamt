import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_progress.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_tile_header_layout.dart';

/// Image, name, brand and remaining stock of an inventory item row.
class InventoryItemRowMainSection extends StatelessWidget {
  /// Creates the main section.
  const new({
    required this.item,
    required this.showSelectionCheckbox,
    required this.isSelected,
    super.key,
  });

  /// The item.
  final InventoryItem item;

  /// The show selection checkbox.
  final bool showSelectionCheckbox;

  /// Whether selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';

    return InventoryTileHeaderLayout(
      leading: InventoryItemImageTile(imageUrl: item.imageUrl),
      badgeText: brand.isEmpty ? null : brand,
      title: item.name,
      titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: item.isFullyConsumed
            ? colors.onSurface.withValues(
                alpha: AppOpacities.inventoryUsedUpName,
              )
            : colors.onSurface,
        fontSize: AppInventoryClosedTile.titleFontSize,
        fontWeight: FontWeight.w700,
        height: AppInventoryClosedTile.titleLineHeight,
        letterSpacing: 0,
      ),
      progressRatio: progress.remainingRatio,
      progressLabel: progress.remainingLabel,
      segmentedByUnits: progress.segmentedByUnits,
      totalUnits: item.initialQuantity,
      remainingUnits: item.quantity,
      showSelectionCheckbox: showSelectionCheckbox,
      isSelected: isSelected,
      showExpandIndicator: false,
      isExpanded: false,
    );
  }
}
