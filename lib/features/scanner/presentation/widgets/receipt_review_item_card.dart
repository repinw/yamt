import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/product_nutrition_summary.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_leading_avatar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card representing a single line item with traffic-light status.
class ReceiptReviewItemCard extends StatelessWidget {
  /// Creates a [ReceiptReviewItemCard].
  const ReceiptReviewItemCard({
    required this.item,
    required this.currencyCode,
    required this.onTap,
    super.key,
    this.onConfirmSuggestion,
    this.onToggleIgnore,
  });

  /// The receipt line item displayed.
  final ReceiptLineItem item;

  /// The currency code for formatting prices.
  final String currencyCode;

  /// Callback when the card is tapped to open item details.
  final VoidCallback onTap;

  /// Callback to confirm the suggested candidate.
  final VoidCallback? onConfirmSuggestion;

  /// Callback to toggle ignore status.
  final VoidCallback? onToggleIgnore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = buildCurrencyFormat(
      locale: locale,
      currencyCode: currencyCode,
    );

    final isIgnored = item.status == ReceiptItemStatus.ignored;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 4,
      ),
      color: _cardColor(colors),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _borderColor(colors),
          width: item.status == ReceiptItemStatus.suggested ? 1.5 : 1,
        ),
      ),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeadingQuantity(colors),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildItemDetails(context, colors, isIgnored),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildPriceAndActions(context, colors, formatter, isIgnored),
                ],
              ),
              if (item.matchedProduct?.hasNutrition == true) ...[
                const SizedBox(height: AppSpacing.sm),
                ProductNutritionSummary(
                  product: item.matchedProduct!,
                  packageSize:
                      item.packageWeight ?? item.matchedProduct!.packageSize,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _cardColor(ColorScheme colors) => switch (item.status) {
    ReceiptItemStatus.confirmed => colors.surface,
    ReceiptItemStatus.suggested => colors.tertiaryContainer.withValues(
      alpha: 0.15,
    ),
    ReceiptItemStatus.unmatched => colors.surfaceContainerLowest,
    ReceiptItemStatus.ignored => colors.surfaceContainerHighest.withValues(
      alpha: 0.3,
    ),
  };

  Widget _buildLeadingQuantity(ColorScheme colors) {
    final quantity = item.quantity.toString().replaceAll(RegExp(r'\.0$'), '');
    return SizedBox(
      width: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            child: ReceiptItemLeadingAvatar(
              status: item.status,
              imageUrl: item.matchedProduct?.imageUrl,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${quantity}x',
            key: Key('receipt_item_quantity_${item.id}'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _borderColor(ColorScheme colors) => switch (item.status) {
    ReceiptItemStatus.confirmed => Colors.green.withValues(alpha: 0.3),
    ReceiptItemStatus.suggested => Colors.amber.shade700,
    ReceiptItemStatus.unmatched => colors.outlineVariant,
    ReceiptItemStatus.ignored => colors.outlineVariant.withValues(alpha: 0.3),
  };

  Widget _buildItemDetails(
    BuildContext context,
    ColorScheme colors,
    bool isIgnored,
  ) {
    final l10n = AppLocalizations.of(context);
    final title = item.matchedProduct?.name ?? item.rawName;
    final subtitle = item.matchedProduct != null ? item.rawName : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: isIgnored ? TextDecoration.lineThrough : null,
            color: isIgnored ? colors.outline : colors.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${l10n?.receiptReviewReceiptPrefix ?? 'Bon'}: $subtitle',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 4),
        _buildItemBadges(context, colors),
      ],
    );
  }

  Widget _buildItemBadges(BuildContext context, ColorScheme colors) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (item.isDeposit)
          _badge(
            l10n?.receiptReviewDepositBadge ?? 'Pfand',
            colors.surfaceContainerHighest,
            null,
          ),
        if (item.discount > 0)
          _badge(
            '-${item.discount.toStringAsFixed(2)} €',
            Colors.teal.withValues(alpha: 0.12),
            Colors.teal,
          ),
      ],
    );
  }

  Widget _badge(String label, Color bg, Color? text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
    ),
  );

  Widget _buildPriceAndActions(
    BuildContext context,
    ColorScheme colors,
    NumberFormat formatter,
    bool isIgnored,
  ) {
    final l10n = AppLocalizations.of(context);
    final effectivePrice = item.effectivePrice;
    final hasDiscount = item.discount > 0;
    final priceColor = hasDiscount
        ? Colors.teal
        : (isIgnored ? colors.outline : colors.onSurface);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDiscount)
              Text(
                formatter.format(item.totalPrice),
                style: TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: colors.outline,
                ),
              ),
            Text(
              formatter.format(effectivePrice),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: isIgnored ? TextDecoration.lineThrough : null,
                color: priceColor,
              ),
            ),
          ],
        ),
        if (item.status == ReceiptItemStatus.suggested &&
            onConfirmSuggestion != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: IconButton(
              key: Key('confirm_item_${item.id}'),
              icon: const Icon(Icons.check_rounded, color: Colors.green),
              iconSize: 20,
              onPressed: onConfirmSuggestion,
              tooltip:
                  l10n?.receiptReviewConfirmSuggestionTooltip ??
                  'Vorschlag übernehmen',
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
