import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_consumption_filter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_consumption_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_all_items_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_groups_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryList extends ConsumerStatefulWidget {
  const InventoryList({
    super.key,
    required this.items,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final List<InventoryItem> items;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

  @override
  ConsumerState<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<InventoryList> {
  var _mode = InventoryListMode.byReceipt;
  var _consumptionFilter = const InventoryConsumptionFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final showBarcodeMarkers = ref.watch(
      barcodeBackfillFeatureFlagsProvider.select(
        (flags) => flags.showInventoryBarcodeMarkers,
      ),
    );
    final activeShoppingListItemKeys = ref.watch(
      activeShoppingListItemKeysProvider,
    );
    final filteredItems = _consumptionFilter.apply(widget.items);
    final hasSourceItems = widget.items.isNotEmpty;
    final hasFilteredItems = filteredItems.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppInsets.page,
          sliver: SliverToBoxAdapter(
            child: InventorySummaryCard(
              items: filteredItems,
              currency: currency,
            ),
          ),
        ),
        if (hasSourceItems)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InventoryListModeToggle(
                    mode: _mode,
                    l10n: l10n,
                    onModeChanged: _onModeChanged,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InventoryConsumptionFilterToggle(
                    showConsumed: _consumptionFilter.showConsumed,
                    showNotConsumed: _consumptionFilter.showNotConsumed,
                    l10n: l10n,
                    onShowConsumedChanged: _onShowConsumedChanged,
                    onShowNotConsumedChanged: _onShowNotConsumedChanged,
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        if (!hasSourceItems)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: AppInsets.pageLarge,
              child: const InventoryEmptyState(),
            ),
          )
        else if (!hasFilteredItems)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: AppInsets.pageLarge,
              child: InventoryEmptyState(
                message: l10n.inventoryFilteredEmptyState,
              ),
            ),
          )
        else if (_mode == InventoryListMode.byReceipt)
          InventoryReceiptGroupsSliver(
            groups: groupInventoryItemsByReceipt(filteredItems),
            currency: currency,
            dateFormat: DateFormat.yMMMd(locale),
            showBarcodeMarkers: showBarcodeMarkers,
            activeShoppingListItemKeys: activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
          )
        else
          InventoryAllItemsSliver(
            items: filteredItems,
            l10n: l10n,
            currency: currency,
            showBarcodeMarkers: showBarcodeMarkers,
            activeShoppingListItemKeys: activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
          ),
      ],
    );
  }

  void _onModeChanged(InventoryListMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _onShowConsumedChanged(bool showConsumed) {
    setState(() {
      _consumptionFilter = _consumptionFilter.toggleConsumed(showConsumed);
    });
  }

  void _onShowNotConsumedChanged(bool showNotConsumed) {
    setState(() {
      _consumptionFilter = _consumptionFilter.toggleNotConsumed(
        showNotConsumed,
      );
    });
  }
}
