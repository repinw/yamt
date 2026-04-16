import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list stats card keys.
class ShoppingListStatsCardKeys {
  const ShoppingListStatsCardKeys._();

  /// The entries value.
  static const entriesValue = Key('shopping_list_stats_entries_value');

  /// The quantity value.
  static const quantityValue = Key('shopping_list_stats_quantity_value');
}

/// Defines shopping list stats card.
class ShoppingListStatsCard extends StatelessWidget {
  /// The shopping list stats card.
  const ShoppingListStatsCard({
    required this.entryCount,
    required this.totalQuantity,
    required this.estimatedTotal,
    required this.currency,
    required this.l10n,
    super.key,
  });

  /// The entry count.
  final int entryCount;

  /// The total quantity.
  final int totalQuantity;

  /// The estimated total.
  final double estimatedTotal;

  /// The currency.
  final NumberFormat currency;

  /// The l10n.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeShopping,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ShoppingStatRow(
              label: l10n.shoppingListStatsEntries,
              value: entryCount.toString(),
              valueKey: ShoppingListStatsCardKeys.entriesValue,
            ),
            const SizedBox(height: AppSpacing.xs),
            _ShoppingStatRow(
              label: l10n.shoppingListStatsQuantity,
              value: totalQuantity.toString(),
              valueKey: ShoppingListStatsCardKeys.quantityValue,
            ),
            const SizedBox(height: AppSpacing.xs),
            _ShoppingStatRow(
              label: l10n.shoppingListStatsEstimatedTotal,
              value: currency.format(estimatedTotal),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingStatRow extends StatelessWidget {
  const _ShoppingStatRow({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          key: valueKey,
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
