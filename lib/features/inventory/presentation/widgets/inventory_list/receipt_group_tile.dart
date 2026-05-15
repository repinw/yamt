import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Callback used to delete an inventory item.
typedef InventoryItemDeleteCallback = Future<bool> Function(String itemId);

/// Callback used to eat an inventory item.
typedef InventoryItemEatCallback =
    Future<bool> Function(String itemId, InventoryItemEatRequest request);

/// Callback used to throw away inventory item quantity.
typedef InventoryItemThrowAwayCallback =
    Future<InventoryItemDiscardResult?> Function(
      String itemId,
      int amount,
      InventoryDiscardReason reason,
    );

/// Actions used by [ReceiptGroupTile] rows.
class ReceiptGroupTileActions {
  /// Creates receipt group tile actions.
  const ReceiptGroupTileActions({
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  /// The on delete item.
  final InventoryItemDeleteCallback onDeleteItem;

  /// The on eat item.
  final InventoryItemEatCallback onEatItem;

  /// The on throw away item.
  final InventoryItemThrowAwayCallback onThrowAwayItem;
}

/// Selection options used by [ReceiptGroupTile] rows.
class ReceiptGroupSelectionOptions {
  /// Creates receipt group selection options.
  const ReceiptGroupSelectionOptions({
    this.isSelectionMode = false,
    this.selectedItemIds = const <String>{},
    this.onItemLongPress = _noopItemSelection,
    this.onSelectionToggle = _noopItemSelection,
  });

  /// Whether selection mode.
  final bool isSelectionMode;

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The on item long press.
  final ValueChanged<String> onItemLongPress;

  /// The on selection toggle.
  final ValueChanged<String> onSelectionToggle;
}

/// Defines receipt group tile.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
])
class ReceiptGroupTile extends StatefulWidget {
  /// The receipt group tile.
  const ReceiptGroupTile({
    required this.group,
    required this.dateFormat,
    required this.activeShoppingListItemKeys,
    required this.actions,
    super.key,
    this.selection = const ReceiptGroupSelectionOptions(),
  });

  /// The group.
  final InventoryReceiptGroup group;

  /// The date format.
  final DateFormat dateFormat;

  /// The active shopping list item keys.
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;

  /// Inventory item row actions.
  final ReceiptGroupTileActions actions;

  /// Inventory item selection options.
  final ReceiptGroupSelectionOptions selection;

  @override
  State<ReceiptGroupTile> createState() => _ReceiptGroupTileState();
}

class _ReceiptGroupTileState extends State<ReceiptGroupTile> {
  var _isExpanded = true;
  var _didRestoreExpansionState = false;

  String get _storageKey => 'receipt_group_${widget.group.key}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestoreExpansionState) {
      return;
    }
    _didRestoreExpansionState = true;

    final restoredState = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _storageKey);
    if (restoredState is bool) {
      _isExpanded = restoredState;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final title = widget.group.title(l10n: l10n, dateFormat: widget.dateFormat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInkWell(
          onTap: widget.selection.isSelectionMode ? null : _toggleExpanded,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      '${widget.group.items.length} '
                              '${l10n.inventoryReceiptGroupItems}'
                          .toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                InventoryExpandIndicator(
                  isExpanded: _isExpanded,
                  enabled: !widget.selection.isSelectionMode,
                  rotationKey: Key(
                    'receipt_group_expand_indicator_${widget.group.key}',
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    children: widget.group.items
                        .map((item) {
                          return InventoryItemRowListEntry(
                            item: item,
                            keyPrefix: 'receipt_item_row',
                            bottomSpacing: AppSpacing.xl,
                            l10n: l10n,
                            activeShoppingListItemKeys:
                                widget.activeShoppingListItemKeys,
                            onDeleteItem: widget.actions.onDeleteItem,
                            onEatItem: widget.actions.onEatItem,
                            onThrowAwayItem: widget.actions.onThrowAwayItem,
                            isSelectionMode: widget.selection.isSelectionMode,
                            isSelected: widget.selection.selectedItemIds
                                .contains(
                                  item.id,
                                ),
                            onItemLongPress: () =>
                                widget.selection.onItemLongPress(item.id),
                            onSelectionToggle: () =>
                                widget.selection.onSelectionToggle(item.id),
                          );
                        })
                        .toList(growable: false),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _toggleExpanded() {
    if (widget.selection.isSelectionMode) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, _isExpanded, identifier: _storageKey);
  }
}

void _noopItemSelection(String _) {}
