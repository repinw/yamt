import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';

const _inventoryReceiptGroupsBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

class InventoryReceiptGroupsSliver extends StatelessWidget {
  const InventoryReceiptGroupsSliver({
    super.key,
    required this.groups,
    required this.dateFormat,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onItemLongPress,
    required this.onSelectionToggle,
  });

  final List<InventoryReceiptGroup> groups;
  final DateFormat dateFormat;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final ValueChanged<String> onItemLongPress;
  final ValueChanged<String> onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        _inventoryReceiptGroupsBottomPadding,
      ),
      sliver: SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            child: ReceiptGroupTile(
              group: group,
              dateFormat: dateFormat,
              showBarcodeMarkers: showBarcodeMarkers,
              activeShoppingListItemKeys: activeShoppingListItemKeys,
              onDeleteItem: onDeleteItem,
              onEatItem: onEatItem,
              onThrowAwayItem: onThrowAwayItem,
              isSelectionMode: isSelectionMode,
              selectedItemIds: selectedItemIds,
              onItemLongPress: onItemLongPress,
              onSelectionToggle: onSelectionToggle,
            ),
          );
        },
      ),
    );
  }
}
