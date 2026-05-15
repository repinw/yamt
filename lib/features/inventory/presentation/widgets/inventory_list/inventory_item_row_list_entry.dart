import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory item row list entry.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  manualProductRecentItemsService,
])
class InventoryItemRowListEntry extends StatelessWidget {
  /// The inventory item row list entry.
  const InventoryItemRowListEntry({
    required this.item,
    required this.keyPrefix,
    required this.bottomSpacing,
    required this.l10n,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
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

  /// The l10n.
  final AppLocalizations l10n;

  /// The active shopping list item keys.
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;

  /// The on delete item.
  final Future<bool> Function(String itemId) onDeleteItem;

  /// Documented member.
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatItem;

  /// The on throw away item.
  final Future<InventoryItemDiscardResult?> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;

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
