import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of summary chips displaying discrepancy, savings, and deposit info.
class ReceiptReviewBadgesRow extends StatelessWidget {
  /// Creates a [ReceiptReviewBadgesRow].
  const new({required this.receipt, required this.formatter, super.key});

  /// The scanned receipt being reviewed.
  final ScannedReceipt receipt;

  /// Localized currency formatter.
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final diff = receipt.totalDiscrepancy;
    final isDiscrepancy = receipt.hasDiscrepancy;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        if (isDiscrepancy && receipt.printedTotal != null)
          Chip(
            avatar: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: colors.error,
            ),
            label: Text(
              l10n?.receiptReviewDifference(formatter.format(diff)) ??
                  'Differenz: ${formatter.format(diff)}',
              style: TextStyle(
                fontSize: 11,
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: colors.errorContainer.withValues(alpha: 0.4),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          )
        else if (receipt.printedTotal != null)
          Chip(
            avatar: const Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.green,
            ),
            label: Text(
              l10n?.receiptReviewSumMatches ?? 'Summe stimmt',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),
        if (receipt.totalSavings > 0)
          Chip(
            avatar: const Icon(
              Icons.local_offer_outlined,
              size: 14,
              color: Colors.teal,
            ),
            label: Text(
              l10n?.receiptReviewDiscount(
                    formatter.format(receipt.totalSavings),
                  ) ??
                  'Rabatt: -${formatter.format(receipt.totalSavings)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.teal.withValues(alpha: 0.1),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),
        if (receipt.totalDeposit > 0)
          Chip(
            avatar: Icon(
              Icons.recycling_outlined,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            label: Text(
              l10n?.receiptReviewDeposit(
                    formatter.format(receipt.totalDeposit),
                  ) ??
                  'Pfand: ${formatter.format(receipt.totalDeposit)}',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
            backgroundColor: colors.surfaceContainerHighest,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),
      ],
    );
  }
}
