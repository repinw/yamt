import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
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
import 'package:yamt/l10n/app_localizations.dart';

class InventoryList extends StatefulWidget {
  const InventoryList({
    super.key,
    required this.items,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.onBuyAgainItem,
  });

  final List<FridgeItem> items;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;
  final Future<bool> Function(FridgeItem item) onBuyAgainItem;

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  var _mode = InventoryListMode.byReceipt;
  var _consumptionFilter = const InventoryConsumptionFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final dateFormat = DateFormat.yMMMd(locale);
    final filteredItems = _consumptionFilter.apply(widget.items);
    final groups = groupInventoryItemsByReceipt(filteredItems);
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
            groups: groups,
            currency: currency,
            dateFormat: dateFormat,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
            onBuyAgainItem: widget.onBuyAgainItem,
          )
        else
          InventoryAllItemsSliver(
            items: filteredItems,
            l10n: l10n,
            currency: currency,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
            onBuyAgainItem: widget.onBuyAgainItem,
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
