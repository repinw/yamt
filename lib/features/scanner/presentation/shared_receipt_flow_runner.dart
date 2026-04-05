import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/shared_receipt_intent.dart';
import 'package:yamt/features/scanner/presentation/receipt_batch_flow_runner.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_flow_runner.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SharedReceiptFlowRunner {
  SharedReceiptFlowRunner({
    required this.context,
    required this.ref,
    required this.l10n,
  }) : _reviewFlow = ReceiptReviewFlowRunner(
         context: context,
         ref: ref,
         l10n: l10n,
       );

  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final ReceiptReviewFlowRunner _reviewFlow;

  void dispose() {
    _reviewFlow.dispose();
  }

  Future<bool> confirmScan(SharedReceiptIntent pendingIntent) async {
    final shouldScan = await showSharedReceiptConfirmationDialog(
      context: context,
      l10n: l10n,
      pendingIntent: pendingIntent,
    );
    return shouldScan == true;
  }

  Future<void> runConfirmed(SharedReceiptIntent pendingIntent) async {
    if (pendingIntent.isBatch) {
      final runner = ReceiptBatchFlowRunner(
        context: context,
        ref: ref,
        l10n: l10n,
        onItemsSaved: _invalidateInventoryItems,
      );
      await runner.runSelections(pendingIntent.selections);
      return;
    }

    await _reviewFlow.runSelection(
      selection: pendingIntent.selections.first,
      onItemsSaved: _invalidateInventoryItems,
    );
  }

  void _invalidateInventoryItems() {
    ref.invalidate(inventoryItemsControllerProvider);
  }
}

Future<bool?> showSharedReceiptConfirmationDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required SharedReceiptIntent pendingIntent,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.inventorySharedReceiptConfirmTitle),
        content: Text(
          pendingIntent.isBatch
              ? l10n.inventorySharedReceiptConfirmMultipleMessage(
                  pendingIntent.selections.length,
                )
              : l10n.inventorySharedReceiptConfirmSingleMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.inventorySharedReceiptConfirmAction),
          ),
        ],
      );
    },
  );
}
