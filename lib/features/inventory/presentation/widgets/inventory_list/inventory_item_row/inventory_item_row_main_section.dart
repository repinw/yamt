import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_tile_header_layout.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/inventory_item_row_view_data.dart';

/// Image, name, brand and remaining stock of an inventory item row.
class InventoryItemRowMainSection extends StatelessWidget {
  /// Creates the main section.
  const new({
    required this.item,
    required this.viewData,
    required this.showSelectionCheckbox,
    required this.isSelected,
    super.key,
  });

  /// The item.
  final InventoryItemRowSnapshot item;

  /// The view data.
  final InventoryItemRowViewData viewData;

  /// The show selection checkbox.
  final bool showSelectionCheckbox;

  /// Whether selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InventoryTileHeaderLayout(
      leading: InventoryItemImageTile(imageUrl: item.imageUrl),
      badgeText: viewData.hasBrand ? viewData.brand : null,
      title: item.name,
      titleStyle: viewData.nameTextStyle,
      progressRatio: viewData.remainingRatio,
      progressLabel: viewData.remainingLabel,
      segmentedByUnits: viewData.segmentedByUnits,
      totalUnits: item.initialQuantity,
      remainingUnits: item.quantity,
      showSelectionCheckbox: showSelectionCheckbox,
      isSelected: isSelected,
      showExpandIndicator: false,
      isExpanded: false,
    );
  }
}
