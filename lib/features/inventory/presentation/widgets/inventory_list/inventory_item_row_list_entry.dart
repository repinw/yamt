import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRowListEntry extends StatelessWidget {
  const InventoryItemRowListEntry({
    super.key,
    required this.item,
    required this.keyPrefix,
    required this.bottomSpacing,
    required this.l10n,
    required this.currency,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.onBuyAgainItem,
  });

  final FridgeItem item;
  final String keyPrefix;
  final double bottomSpacing;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;
  final Future<bool> Function(FridgeItem item) onBuyAgainItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: RepaintBoundary(
        child: InventoryItemRow(
          key: ValueKey<String>('${keyPrefix}_${item.id}'),
          item: item,
          l10n: l10n,
          currency: currency,
          onDeletePressed: onDeleteItem,
          onEatPressed: onEatItem,
          onThrowAwayPressed: onThrowAwayItem,
          onBuyAgainPressed: onBuyAgainItem,
        ),
      ),
    );
  }
}
