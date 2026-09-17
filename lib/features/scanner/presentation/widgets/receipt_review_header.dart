import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_review_badges_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header widget displaying receipt metadata, price validation,
/// and summary chips.
class ReceiptReviewHeader extends StatelessWidget {
  /// Creates a [ReceiptReviewHeader].
  const new({
    required this.receipt,
    required this.onEditStore,
    required this.onEditDate,
    super.key,
    this.onConfirmAllSuggestions,
  });

  /// The receipt being reviewed.
  final ScannedReceipt receipt;

  /// Callback when user taps to edit the store name.
  final VoidCallback onEditStore;

  /// Callback when user taps to change the receipt date.
  final VoidCallback onEditDate;

  /// Callback to confirm all suggested product candidates at once.
  final VoidCallback? onConfirmAllSuggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = buildCurrencyFormat(
      locale: locale,
      currencyCode: receipt.currency,
    );

    final hasSuggestions = receipt.items.any(
      (item) => item.status == ReceiptItemStatus.suggested,
    );

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreAndDateRow(context, colors),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _buildPriceSummary(context, colors, formatter),
            const SizedBox(height: AppSpacing.md),
            ReceiptReviewBadgesRow(receipt: receipt, formatter: formatter),
            if (hasSuggestions && onConfirmAllSuggestions != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildSuggestionsButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreAndDateRow(BuildContext context, ColorScheme colors) {
    final l10n = AppLocalizations.of(context);
    final formattedDate = receipt.dateTime != null
        ? DateFormat('dd.MM.yyyy, HH:mm').format(receipt.dateTime!)
        : (l10n?.receiptReviewNoDate ?? 'Kein Datum erkannt');

    return Row(
      children: [
        Expanded(
          child: AppInkWell(
            onTap: onEditStore,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      (receipt.storeName == null || receipt.storeName!.isEmpty)
                          ? (l10n?.receiptReviewUnknownStore ??
                                'Unbekannter Händler')
                          : receipt.storeName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppInkWell(
          onTap: onEditDate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(
    BuildContext context,
    ColorScheme colors,
    NumberFormat formatter,
  ) {
    final l10n = AppLocalizations.of(context);
    final total = receipt.printedTotal;
    final printedTotal = total != null ? formatter.format(total) : '–';
    final calculatedTotal = formatter.format(receipt.calculatedTotal);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.receiptReviewPrintedTotal ?? 'Bon-Summe',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              printedTotal,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n?.receiptReviewCalculatedTotal ?? 'Berechnete Summe',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              calculatedTotal,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: receipt.hasDiscrepancy ? colors.error : colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionsButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        key: const Key('confirm_all_suggestions_button'),
        onPressed: onConfirmAllSuggestions,
        icon: const Icon(Icons.done_all_rounded, size: 18),
        label: Text(
          l10n?.receiptReviewConfirmAllSuggestions ??
              'Alle Vorschläge übernehmen',
        ),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
