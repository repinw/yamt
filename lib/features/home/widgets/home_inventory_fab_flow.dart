import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomeInventoryFabFlow {
  const HomeInventoryFabFlow._();

  static Future<void> openActionSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    final isCameraEnabled = ref.read(receiptCameraSupportedProvider);

    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return InventoryReceiptActionsSheet(
          isCameraEnabled: isCameraEnabled,
          onScanCameraTap: () {
            Navigator.of(sheetContext).pop();
            unawaited(_runFlow(context, ref, l10n, ReceiptInputSource.camera));
          },
          onUploadFileTap: () {
            Navigator.of(sheetContext).pop();
            unawaited(_runBatchFlow(context, ref, l10n));
          },
        );
      },
    );
  }

  static Future<void> _runFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ReceiptInputSource source,
  ) async {
    final controller = ref.read(receiptCaptureFlowControllerProvider.notifier);
    final result = await controller.run(source: source);
    if (!context.mounted) {
      return;
    }

    if (result.status == ReceiptCaptureFlowStatus.completed) {
      await _openReviewSheet(
        context: context,
        ref: ref,
        l10n: l10n,
        controller: controller,
        mappedItems: result.mappedItems ?? const <FridgeItem>[],
      );
      return;
    }

    final message = _messageForFlowResult(result, l10n);
    if (message == null) {
      return;
    }
    _showSnackBar(context, message);
  }

  static Future<void> _runBatchFlow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final captureController = ref.read(
      receiptCaptureFlowControllerProvider.notifier,
    );
    final batchController = ref.read(
      receiptBatchFlowControllerProvider.notifier,
    );
    batchController.reset();

    var hasOpenedFirstReview = false;
    var isReviewOpen = false;
    String? feedbackMessage;
    final container = ProviderScope.containerOf(context, listen: false);

    Future<void> openReviewForIndex(int index) async {
      if (isReviewOpen) {
        return;
      }
      final mappedItems = container
          .read(receiptBatchFlowControllerProvider)
          .mappedItemsForIndex(index);
      if (mappedItems.isEmpty || !context.mounted) {
        return;
      }

      isReviewOpen = true;
      try {
        final saved = await _openReviewSheet(
          context: context,
          ref: ref,
          l10n: l10n,
          controller: captureController,
          mappedItems: mappedItems,
        );
        if (!context.mounted || !saved) {
          return;
        }
        batchController.markReviewed(index);
      } catch (error, stackTrace) {
        log(
          'Receipt review sheet failed unexpectedly',
          name: 'HomeInventoryFabFlow',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        isReviewOpen = false;
      }
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isDialogClosed = false;
    final progressDialog =
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return InventoryReceiptBatchProgressDialog(
              onReviewTap: openReviewForIndex,
              onCloseTap: () {
                if (rootNavigator.mounted) {
                  rootNavigator.pop();
                }
              },
            );
          },
        ).whenComplete(() {
          isDialogClosed = true;
        });

    Future<void> closeProgressDialog() async {
      if (!isDialogClosed && rootNavigator.mounted) {
        rootNavigator.pop();
      }
      await progressDialog;
    }

    final subscription = container.listen(receiptBatchFlowControllerProvider, (
      previous,
      next,
    ) {
      final pendingIndex = next.pendingAutoReviewIndex;
      if (pendingIndex == null || isReviewOpen || !context.mounted) {
        return;
      }
      batchController.consumePendingAutoReview();
      if (hasOpenedFirstReview) {
        return;
      }
      hasOpenedFirstReview = true;
      unawaited(openReviewForIndex(pendingIndex));
    }, fireImmediately: true);

    try {
      await batchController.runFileBatch();
      final batchState = container.read(receiptBatchFlowControllerProvider);

      if (!context.mounted) {
        return;
      }
      if (batchState.status == ReceiptBatchFlowStatus.inputCanceled) {
        return;
      }
      if (batchState.status == ReceiptBatchFlowStatus.inputFailed) {
        feedbackMessage = l10n.inventoryReceiptSelectionFailed;
        return;
      }
      final progress = batchState.progress;
      final isBatchComplete =
          progress.totalCount == 0 ||
          progress.processedCount == progress.totalCount;
      if (!isBatchComplete) {
        feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
        return;
      }
      if (batchState.status != ReceiptBatchFlowStatus.completed) {
        feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
        return;
      }
      final hasMappedItems = batchState.mappedItemsByIndex.values
          .expand((items) => items)
          .isNotEmpty;
      if (!hasMappedItems) {
        feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
        return;
      }

      await progressDialog;
    } catch (error, stackTrace) {
      log(
        'Receipt batch flow failed unexpectedly',
        name: 'HomeInventoryFabFlow',
        error: error,
        stackTrace: stackTrace,
      );
      feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
    } finally {
      await closeProgressDialog();
      subscription.close();
      batchController.reset();
      if (feedbackMessage != null && context.mounted) {
        _showSnackBar(context, feedbackMessage);
      }
    }
  }

  static Future<bool> _openReviewSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ReceiptCaptureFlowController controller,
    required List<FridgeItem> mappedItems,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return InventoryReceiptReviewSheet(
          items: mappedItems,
          onCancelTap: () => Navigator.of(sheetContext).pop(false),
          onSaveTap: (reviewedItems) async {
            final saved = await controller.persistReviewedItems(reviewedItems);
            if (!sheetContext.mounted) {
              return;
            }
            Navigator.of(sheetContext).pop(saved);

            if (!context.mounted) {
              return;
            }

            if (saved) {
              ref.invalidate(fridgeItemsControllerProvider);
              _showSnackBar(context, l10n.inventoryReceiptSaveSucceeded);
              return;
            }
            _showSnackBar(context, l10n.inventoryReceiptSaveFailed);
          },
        );
      },
    ).then((saved) => saved ?? false);
  }

  static String? _messageForFlowResult(
    ReceiptCaptureFlowResult result,
    AppLocalizations l10n,
  ) {
    return switch (result.status) {
      ReceiptCaptureFlowStatus.completed => null,
      ReceiptCaptureFlowStatus.inputCanceled => null,
      ReceiptCaptureFlowStatus.inputUnsupported =>
        l10n.inventoryActionCameraUnsupported,
      ReceiptCaptureFlowStatus.inputFailed =>
        l10n.inventoryReceiptSelectionFailed,
      ReceiptCaptureFlowStatus.analysisFailed =>
        l10n.inventoryReceiptAnalysisFailed,
    };
  }

  static void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
