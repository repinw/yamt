import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';

class InventoryReceiptGroupsSliver extends StatelessWidget {
  const InventoryReceiptGroupsSliver({
    super.key,
    required this.groups,
    required this.currency,
    required this.dateFormat,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.onBuyAgainItem,
  });

  final List<InventoryReceiptGroup> groups;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;
  final Future<bool> Function(FridgeItem item) onBuyAgainItem;

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
              onBuyAgainItem: onBuyAgainItem,
            ),
          );
        },
      ),
    );
  }
}
