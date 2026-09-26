import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';

/// Inventory item row with its list spacing.
class InventoryItemRowListEntry extends StatelessWidget {
  /// The inventory item row list entry.
  const new({
    required this.item,
    required this.keyPrefix,
    required this.bottomSpacing,
    super.key,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onItemLongPress,
    this.onSelectionToggle,
  });

  /// The item.
  final InventoryItem item;

  /// The key prefix.
  final String keyPrefix;

  /// The bottom spacing.
  final double bottomSpacing;

  /// Whether selection mode.
  final bool isSelectionMode;

  /// Whether selected.
  final bool isSelected;

  /// The on item long press.
  final VoidCallback? onItemLongPress;

  /// The on selection toggle.
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final canStartSelection = item.usesAmountProgress
        ? item.currentAmount > 0
        : item.quantity > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: RepaintBoundary(
        child: InventoryItemRow(
          key: ValueKey<String>('${keyPrefix}_${item.id}'),
          item: item,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          onStartSelection: canStartSelection ? onItemLongPress : null,
          onSelectionToggle: onSelectionToggle,
        ),
      ),
    );
  }
}
