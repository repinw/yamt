import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryListBottomPadding = AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

class InventoryAllItemsSliver extends StatefulWidget {
  const InventoryAllItemsSliver({
    super.key,
    required this.items,
    required this.l10n,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.sortMode,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onItemLongPress,
    required this.onSelectionToggle,
  });

  final List<InventoryItem> items;
  final AppLocalizations l10n;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final InventoryItemSortMode sortMode;
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
  final Set<String> selectedItemIds;
  final ValueChanged<String> onItemLongPress;
  final ValueChanged<String> onSelectionToggle;

  @override
  State<InventoryAllItemsSliver> createState() =>
      _InventoryAllItemsSliverState();
}

class _InventoryAllItemsSliverState extends State<InventoryAllItemsSliver> {
  late InventorySortedItemsCache _sortedItemsCache;
  late List<InventoryItem> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItemsCache = InventorySortedItemsCache.fromItems(
      widget.items,
      sortMode: widget.sortMode,
    );
    _sortedItems = _sortedItemsCache.materialize(widget.items);
  }

  @override
  void didUpdateWidget(covariant InventoryAllItemsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.items, widget.items) &&
        oldWidget.sortMode == widget.sortMode) {
      return;
    }
    _sortedItemsCache = _sortedItemsCache.update(
      widget.items,
      sortMode: widget.sortMode,
    );
    _sortedItems = _sortedItemsCache.materialize(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        _inventoryListBottomPadding,
      ),
      sliver: SliverList.builder(
        itemCount: _sortedItems.length,
        itemBuilder: (context, index) {
          final item = _sortedItems[index];
          return InventoryItemRowListEntry(
            item: item,
            keyPrefix: 'inventory_item_row',
            bottomSpacing: AppSpacing.xl,
            l10n: widget.l10n,
            showBarcodeMarkers: widget.showBarcodeMarkers,
            activeShoppingListItemKeys: widget.activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
            isSelectionMode: widget.isSelectionMode,
            isSelected: widget.selectedItemIds.contains(item.id),
            onItemLongPress: () => widget.onItemLongPress(item.id),
            onSelectionToggle: () => widget.onSelectionToggle(item.id),
          );
        },
      ),
    );
  }
}
