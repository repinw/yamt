import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ReceiptGroupTile extends StatefulWidget {
  const ReceiptGroupTile({
    super.key,
    required this.group,
    required this.currency,
    required this.dateFormat,
    required this.showBarcodeMarkers,
    required this.activeShoppingListItemKeys,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final InventoryReceiptGroup group;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final bool showBarcodeMarkers;
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

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
        InkWell(
          onTap: _toggleExpanded,
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
                            currency: widget.currency,
                            showBarcodeMarkers: widget.showBarcodeMarkers,
                            activeShoppingListItemKeys:
                                widget.activeShoppingListItemKeys,
                            onDeleteItem: widget.onDeleteItem,
                            onEatItem: widget.onEatItem,
                            onThrowAwayItem: widget.onThrowAwayItem,
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
    setState(() {
      _isExpanded = !_isExpanded;
    });
    PageStorage.maybeOf(
      context,
    )?.writeState(context, _isExpanded, identifier: _storageKey);
  }
}
