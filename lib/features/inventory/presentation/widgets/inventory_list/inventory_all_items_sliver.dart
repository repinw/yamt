import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryAllItemsSliver extends StatefulWidget {
  const InventoryAllItemsSliver({
    super.key,
    required this.items,
    required this.l10n,
    required this.currency,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final List<FridgeItem> items;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

  @override
  State<InventoryAllItemsSliver> createState() =>
      _InventoryAllItemsSliverState();
}

class _InventoryAllItemsSliverState extends State<InventoryAllItemsSliver> {
  late InventorySortedItemsCache _sortedItemsCache;

  @override
  void initState() {
    super.initState();
    _sortedItemsCache = InventorySortedItemsCache.fromItems(widget.items);
  }

  @override
  void didUpdateWidget(covariant InventoryAllItemsSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortedItemsCache = _sortedItemsCache.update(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortedItemsCache.materialize(widget.items);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxxxl + AppSpacing.xxxxl,
      ),
      sliver: SliverList.builder(
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          final item = sortedItems[index];
          return InventoryItemRowListEntry(
            item: item,
            keyPrefix: 'inventory_item_row',
            bottomSpacing: AppSpacing.sm,
            l10n: widget.l10n,
            currency: widget.currency,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
          );
        },
      ),
    );
  }
}
