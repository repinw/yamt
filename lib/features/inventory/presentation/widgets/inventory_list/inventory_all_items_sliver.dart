import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

const double _inventoryListBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

/// Defines inventory all items sliver.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  manualProductRecentItemsService,
])
class InventoryAllItemsSliver extends StatefulWidget {
  /// The inventory all items sliver.
  const InventoryAllItemsSliver({
    required this.items,
    required this.l10n,

    /// Documented member.
    required this.activeShoppingListItemKeys,

    /// Documented member.
    required this.sortMode,

    /// Documented member.
    required this.onDeleteItem,

    /// Documented member.
    required this.onEatItem,

    /// Documented member.
    required this.onThrowAwayItem,

    /// Documented member.
    required this.isSelectionMode,
    required this.selectedItemIds,

    /// Documented member.
    required this.onItemLongPress,
    required this.onSelectionToggle,
    super.key,
  });

  /// The items.
  final List<InventoryItem> items;

  /// The l10n.
  final AppLocalizations l10n;

  /// The active shopping list item keys.
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;

  /// The sort mode.
  final InventoryItemSortMode sortMode;

  /// The on delete item.
  final Future<bool> Function(String itemId) onDeleteItem;

  /// The on eat item.
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

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The on item long press.
  final ValueChanged<String> onItemLongPress;

  /// The on selection toggle.
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
    final horizontalPadding = responsivePageHorizontalPadding(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
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
