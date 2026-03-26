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
  var _isExpanded = false;
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
    final subtitle = widget.group.subtitle(
      l10n: l10n,
      currency: widget.currency,
    );
    final radius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.sectionCardDecoration(
        colors,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey<String>(_storageKey),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: _onExpansionChanged,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            tilePadding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.md,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            iconColor: colors.primary,
            collapsedIconColor: colors.onSurfaceVariant,
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            children: _isExpanded
                ? widget.group.items
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
                      .toList(growable: false)
                : const <Widget>[],
          ),
        ),
      ),
    );
  }

  void _onExpansionChanged(bool isExpanded) {
    if (_isExpanded != isExpanded) {
      setState(() {
        _isExpanded = isExpanded;
      });
    }
    PageStorage.maybeOf(
      context,
    )?.writeState(context, isExpanded, identifier: _storageKey);
  }
}
