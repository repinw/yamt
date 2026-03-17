import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryAllItemsSliver extends StatefulWidget {
  const InventoryAllItemsSliver({
    super.key,
    required this.items,
    required this.l10n,
    required this.currency,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final List<InventoryItem> items;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

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
    _sortedItemsCache = InventorySortedItemsCache.fromItems(widget.items);
    _sortedItems = _sortedItemsCache.materialize(widget.items);
  }

  @override
  void didUpdateWidget(covariant InventoryAllItemsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.items, widget.items)) {
      return;
    }
    _sortedItemsCache = _sortedItemsCache.update(widget.items);
    _sortedItems = _sortedItemsCache.materialize(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxxxl + AppSpacing.xxxxl,
      ),
      sliver: SliverList.builder(
        itemCount: _sortedItems.length,
        itemBuilder: (context, index) {
          final item = _sortedItems[index];
          return InventoryItemRowListEntry(
            item: item,
            keyPrefix: 'inventory_item_row',
            bottomSpacing: AppSpacing.sm,
            l10n: widget.l10n,
            currency: widget.currency,
            showBarcodeMarkers: widget.showBarcodeMarkers,
            activeShoppingListItemKeys: widget.activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
          );
        },
      ),
    );
  }
}
