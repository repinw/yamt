import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory receipt batch progress dialog.
@Dependencies([ReceiptBatchFlowController])
class InventoryReceiptBatchProgressDialog extends ConsumerWidget {
  /// The inventory receipt batch progress dialog.
  const InventoryReceiptBatchProgressDialog({
    required this.onReviewTap,
    required this.onCloseTap,
    super.key,
  });

  /// The on review tap.
  final Future<void> Function(int index) onReviewTap;

  /// The on close tap.
  final VoidCallback onCloseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final progress = batchState.progress;
    final reviewableIndices = batchState.reviewableIndices;
    final reviewedIndices = batchState.reviewedIndices;
    final activeReviewIndex = batchState.activeReviewIndex;

    return AlertDialog(
      title: Text(l10n.inventoryReceiptBatchTitle),
      content: SizedBox(
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
                    trailing: _buildReviewAction(
                      l10n: l10n,
                      index: index,
                      reviewableIndices: reviewableIndices,
                      reviewedIndices: reviewedIndices,
                      activeReviewIndex: activeReviewIndex,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: batchState.canClose ? onCloseTap : null,
          child: Text(l10n.inventoryReceiptBatchCloseAction),
        ),
      ],
    );
  }

  Widget? _buildReviewAction({
    required AppLocalizations l10n,
    required int index,
    required Set<int> reviewableIndices,
    required Set<int> reviewedIndices,
    required int? activeReviewIndex,
  }) {
    if (!reviewableIndices.contains(index)) {
      return null;
    }
    if (reviewedIndices.contains(index)) {
      return Text(
        l10n.inventoryReceiptBatchReviewed,
        style: const TextStyle(fontSize: 12),
      );
    }
    final isAnyReviewOpen = activeReviewIndex != null;
    return TextButton(
      onPressed: isAnyReviewOpen ? null : () => onReviewTap(index),
      child: Text(l10n.inventoryReceiptBatchReviewAction),
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
