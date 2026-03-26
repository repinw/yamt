import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';

const _inventoryReceiptGroupsBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

class InventoryReceiptGroupsSliver extends StatelessWidget {
  const InventoryReceiptGroupsSliver({
    super.key,
    required this.groups,
    required this.currency,
    required this.dateFormat,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final List<InventoryReceiptGroup> groups;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

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
              currency: currency,
              dateFormat: dateFormat,
              showBarcodeMarkers: showBarcodeMarkers,
              activeShoppingListItemKeys: activeShoppingListItemKeys,
              onDeleteItem: onDeleteItem,
              onEatItem: onEatItem,
              onThrowAwayItem: onThrowAwayItem,
            ),
          );
        },
      ),
    );
  }
}
