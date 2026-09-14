import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sticky bottom bar displaying readiness status and save action.
class ReceiptReviewBottomBar extends StatelessWidget {
  /// Creates a [ReceiptReviewBottomBar].
  const ReceiptReviewBottomBar({
    required this.receipt,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  /// The receipt being reviewed.
  final ScannedReceipt receipt;

  /// Whether receipt saving is currently in progress.
  final bool isSaving;

  /// Callback when save button is pressed.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isReady = receipt.isReadyToSave;
    final openCount = receipt.unresolvedCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isReady)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  l10n?.receiptReviewOpenItemsCount(openCount) ??
                      'Noch $openCount Position(en) offen',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('save_receipt_button'),
                onPressed: isReady && !isSaving ? onSave : null,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n?.receiptReviewSaveAction ??
                            'Ins Inventar übernehmen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
