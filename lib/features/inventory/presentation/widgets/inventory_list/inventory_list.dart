import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';

class InventoryList extends StatelessWidget {
  const InventoryList({
    super.key,
    required this.items,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final List<FridgeItem> items;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final dateFormat = DateFormat.yMMMd(locale);
    final groups = groupInventoryItemsByReceipt(items);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: AppInsets.page,
          sliver: SliverToBoxAdapter(
            child: InventorySummaryCard(items: items, currency: currency),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xs,
            ),
            child: InventorySectionHeader(itemCount: items.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        if (groups.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: AppInsets.pageLarge,
              child: const InventoryEmptyState(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxxxl + AppSpacing.xxxxl,
            ),
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReceiptGroupTile(
                    group: group,
                    currency: currency,
                    dateFormat: dateFormat,
                    onDeleteItem: onDeleteItem,
                    onEatItem: onEatItem,
                    onThrowAwayItem: onThrowAwayItem,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
