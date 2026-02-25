import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptBatchProgressDialog extends StatelessWidget {
  const InventoryReceiptBatchProgressDialog({
    super.key,
    required this.progressListenable,
  });

  final ValueListenable<ReceiptBatchProgress> progressListenable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.inventoryReceiptBatchTitle),
      content: ValueListenableBuilder<ReceiptBatchProgress>(
        valueListenable: progressListenable,
        builder: (context, progress, child) {
          return SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inventoryReceiptBatchProgress(
                    progress.processedCount,
                    progress.totalCount,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: progress.items.length,
                    itemBuilder: (context, index) {
                      final item = progress.items[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _statusLeading(item.status),
                        title: Text(
                          item.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_statusLabel(l10n, item.status)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusLeading(ReceiptBatchItemStatus status) {
    return switch (status) {
      ReceiptBatchItemStatus.queued => const Icon(Icons.schedule_outlined),
      ReceiptBatchItemStatus.processing => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      ReceiptBatchItemStatus.succeeded => const Icon(
        Icons.check_circle_outline,
      ),
      ReceiptBatchItemStatus.failed => const Icon(Icons.error_outline),
    };
  }

  String _statusLabel(AppLocalizations l10n, ReceiptBatchItemStatus status) {
    return switch (status) {
      ReceiptBatchItemStatus.queued => l10n.inventoryReceiptBatchQueued,
      ReceiptBatchItemStatus.processing => l10n.inventoryReceiptBatchProcessing,
      ReceiptBatchItemStatus.succeeded => l10n.inventoryReceiptBatchSucceeded,
      ReceiptBatchItemStatus.failed => l10n.inventoryReceiptBatchFailed,
    };
  }
}
