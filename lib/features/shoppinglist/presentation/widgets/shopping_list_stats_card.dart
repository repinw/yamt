import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ShoppingListStatsCard extends StatelessWidget {
  const ShoppingListStatsCard({
    super.key,
    required this.entryCount,
    required this.totalQuantity,
    required this.estimatedTotal,
    required this.currency,
    required this.l10n,
  });

  final int entryCount;
  final int totalQuantity;
  final double estimatedTotal;
  final NumberFormat currency;
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
            ),
            const SizedBox(height: AppSpacing.xs),
            _ShoppingStatRow(
              label: l10n.shoppingListStatsQuantity,
              value: totalQuantity.toString(),
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
  const _ShoppingStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
