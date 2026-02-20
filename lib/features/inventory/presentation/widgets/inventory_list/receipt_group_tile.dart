import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ReceiptGroupTile extends StatelessWidget {
  const ReceiptGroupTile({
    super.key,
    required this.group,
    required this.currency,
    required this.dateFormat,
    required this.onDeleteItem,
    required this.onThrowAwayItem,
  });

  final InventoryReceiptGroup group;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId) onThrowAwayItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = group.title(l10n: l10n, dateFormat: dateFormat);
    final subtitle = group.subtitle(l10n: l10n, currency: currency);

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey<String>('receipt_group_${group.key}'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        children: group.items
            .map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: RepaintBoundary(
                  child: InventoryItemRow(
                    item: item,
                    l10n: l10n,
                    currency: currency,
                    onDeletePressed: onDeleteItem,
                    onThrowAwayPressed: onThrowAwayItem,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
