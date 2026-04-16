import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Footer summary that shows total, savable, and excluded receipt prices.
class InventoryReceiptReviewPriceOverview extends StatelessWidget {
  /// The inventory receipt review price overview.
  const InventoryReceiptReviewPriceOverview({
    required this.totalPrice,
    required this.storablePrice,
    required this.excludedPrice,
    required this.currency,
    super.key,
  });

  /// The total price.
  final double totalPrice;

  /// The storable price.
  final double storablePrice;

  /// The excluded price.
  final double excludedPrice;

  /// The currency.
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const _DashedDivider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inventoryReceiptReviewPriceTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.inventoryReceiptReviewPriceTotal,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Text(
              currency.format(totalPrice),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PriceRow(
          label: l10n.inventoryReceiptReviewPriceSavable,
          value: currency.format(storablePrice),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PriceRow(
          label: l10n.inventoryReceiptReviewPriceExcluded,
          value: currency.format(excludedPrice),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: style),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Row(
          children: List<Widget>.generate(
            dashCount,
            (_) => Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(right: 4),
                color: colors.outlineVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
