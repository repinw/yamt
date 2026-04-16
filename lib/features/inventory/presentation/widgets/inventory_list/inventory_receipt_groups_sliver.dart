import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';

const _inventoryReceiptGroupsBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

/// Defines inventory receipt groups sliver.
@Dependencies([inventoryItemRepository, InventoryItemsController])
class InventoryReceiptGroupsSliver extends StatelessWidget {
  /// The inventory receipt groups sliver.
  const InventoryReceiptGroupsSliver({
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
    super.key,
  });

  /// The groups.
  final List<InventoryReceiptGroup> groups;

  /// The date format.
  final DateFormat dateFormat;

  /// The show barcode markers.
  final bool showBarcodeMarkers;

  /// The active shopping list item keys.
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;

  /// The on delete item.
  final Future<bool> Function(String itemId) onDeleteItem;

  /// Documented member.
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatItem;

  /// The on throw away item.
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;

  /// Whether selection mode.
  final bool isSelectionMode;

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The on item long press.
  final ValueChanged<String> onItemLongPress;

  /// The on selection toggle.
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
