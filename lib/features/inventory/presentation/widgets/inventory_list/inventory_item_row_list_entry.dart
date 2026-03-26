import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRowListEntry extends StatelessWidget {
  const InventoryItemRowListEntry({
    super.key,
    required this.item,
    required this.keyPrefix,
    required this.bottomSpacing,
    required this.l10n,
    required this.currency,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final InventoryItem item;
  final String keyPrefix;
  final double bottomSpacing;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

  @override
  Widget build(BuildContext context) {
    final isAlreadyInShoppingList = isInventoryItemInActiveShoppingList(
      item: item,
      activeItemKeys: activeShoppingListItemKeys,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: RepaintBoundary(
        child: InventoryItemRow(
          key: ValueKey<String>('${keyPrefix}_${item.id}'),
          expansionStorageKey: '${keyPrefix}_${item.id}',
          item: item,
          l10n: l10n,
          currency: currency,
          showBarcodeMarkers: showBarcodeMarkers,
          isAlreadyInShoppingList: isAlreadyInShoppingList,
          onDeletePressed: onDeleteItem,
          onEatPressed: onEatItem,
          onThrowAwayPressed: onThrowAwayItem,
        ),
      ),
    );
  }
}
