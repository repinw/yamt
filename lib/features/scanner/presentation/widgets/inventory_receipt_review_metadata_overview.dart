import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Metadata card that shows store, receipt date, and receipt time.
class InventoryReceiptReviewMetadataOverview extends StatelessWidget {
  /// The inventory receipt review metadata overview.
  const InventoryReceiptReviewMetadataOverview({
    required this.storeName,
    required this.receiptDate,
    required this.receiptTimeText,
    super.key,
  });

  /// The store name.
  final String storeName;

  /// The receipt date.
  final DateTime? receiptDate;

  /// The receipt time text.
  final String? receiptTimeText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final receiptDateText = receiptDate == null
        ? l10n.inventoryReceiptReviewNoDate
        : DateFormat.yMd(locale).format(receiptDate!);
    final receiptMetaText = switch (receiptTimeText?.trim()) {
      final String time when time.isNotEmpty => '$receiptDateText • $time',
      _ => receiptDateText,
    };

    return DecoratedBox(
      decoration: AppReceiptReviewSurfaces.panelDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.storefront, color: colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        receiptMetaText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
