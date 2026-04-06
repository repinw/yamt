import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRowListEntry extends StatelessWidget {
  const InventoryItemRowListEntry({
    super.key,
    required this.item,
    required this.keyPrefix,
    required this.bottomSpacing,
    required this.l10n,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onItemLongPress,
    this.onSelectionToggle,
  });

  final InventoryItem item;
  final String keyPrefix;
  final double bottomSpacing;
  final AppLocalizations l10n;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatItem;
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onItemLongPress;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final isAlreadyInShoppingList = isInventoryItemInActiveShoppingList(
      item: item,
      activeItemKeys: activeShoppingListItemKeys,
    );
    final canStartSelection = item.usesAmountProgress
        ? item.currentAmount > 0
        : item.quantity > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: RepaintBoundary(
        child: InventoryItemRow(
          key: ValueKey<String>('${keyPrefix}_${item.id}'),
          expansionStorageKey: '${keyPrefix}_${item.id}',
          item: item,
          l10n: l10n,
          showBarcodeMarkers: showBarcodeMarkers,
          isAlreadyInShoppingList: isAlreadyInShoppingList,
          onDeletePressed: onDeleteItem,
          onEatPressed: onEatItem,
          onThrowAwayPressed: onThrowAwayItem,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          onStartSelection: canStartSelection ? onItemLongPress : null,
          onSelectionToggle: onSelectionToggle,
        ),
      ),
    );
  }
}
