import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';

const double _inventoryListBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

/// Defines inventory all items sliver.
class InventoryAllItemsSliver extends StatefulWidget {
  /// The inventory all items sliver.
  const new({
    required this.items,

    /// Documented member.
    required this.viewMode,

    /// Documented member.
    required this.sortMode,

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

  /// Card layout mode.
  final InventoryListViewMode viewMode;

  /// The sort mode.
  final InventoryItemSortMode sortMode;

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
        0,
        horizontalPadding,
        _inventoryListBottomPadding,
      ),
      sliver: widget.viewMode == InventoryListViewMode.tiles
          ? _buildTileSliver()
          : _buildListSliver(),
    );
  }

  SliverList _buildListSliver() {
    return SliverList.builder(
      key: const Key('inventory_items_list_view'),
      itemCount: _sortedItems.length,
      itemBuilder: (context, index) =>
          _buildItemEntry(_sortedItems[index], bottomSpacing: AppSpacing.xl),
    );
  }

  SliverGrid _buildTileSliver() {
    return SliverGrid(
      key: const Key('inventory_items_tile_view'),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppInventoryClosedTile.gridMaxCrossAxisExtent,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.lg,
        mainAxisExtent: AppInventoryClosedTile.inventoryGridMainAxisExtent,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildItemEntry(_sortedItems[index], bottomSpacing: 0),
        childCount: _sortedItems.length,
      ),
    );
  }

  InventoryItemRowListEntry _buildItemEntry(
    InventoryItem item, {
    required double bottomSpacing,
  }) {
    return InventoryItemRowListEntry(
      item: item,
      keyPrefix: 'inventory_item_row',
      bottomSpacing: bottomSpacing,
      isSelectionMode: widget.isSelectionMode,
      isSelected: widget.selectedItemIds.contains(item.id),
      onItemLongPress: () => widget.onItemLongPress(item.id),
      onSelectionToggle: () => widget.onSelectionToggle(item.id),
    );
  }
}
