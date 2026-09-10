import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final style = Theme.of(context).textTheme;
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entryCount.toString(),
              key: ShoppingListStatsCardKeys.entriesValue,
              style: style.headlineSmall,
            ),
            Text(l10n.shoppingListStatsEntries, style: style.bodySmall),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              totalQuantity.toString(),
              key: ShoppingListStatsCardKeys.quantityValue,
              style: style.headlineSmall,
            ),
            Text(l10n.shoppingListStatsQuantity, style: style.bodySmall),
          ],
        ),
        if (estimatedTotal > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currency.format(estimatedTotal), style: style.headlineSmall),
              Text(
                l10n.shoppingListStatsEstimatedTotal,
                style: style.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
