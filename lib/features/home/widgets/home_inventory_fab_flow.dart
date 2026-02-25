import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
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
    final controller = ref.read(receiptCaptureFlowControllerProvider.notifier);
    final progressListenable = ValueNotifier<ReceiptBatchProgress>(
      const ReceiptBatchProgress(items: <ReceiptBatchItemProgress>[]),
    );
    final dialogReady = Completer<void>();
    NavigatorState? dialogNavigator;
    final progressDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (sheetContext) {
        dialogNavigator = Navigator.of(sheetContext);
        if (!dialogReady.isCompleted) {
          dialogReady.complete();
        }
        return InventoryReceiptBatchProgressDialog(
          progressListenable: progressListenable,
        );
      },
    );
    await dialogReady.future;

    final result = await controller.runFileBatch(
      onProgress: (progress) {
        progressListenable.value = progress;
      },
    );

    final navigator = dialogNavigator;
    if (navigator?.mounted ?? false) {
      navigator!.pop();
    }
    await progressDialog;
    progressListenable.dispose();

    if (!context.mounted) {
      return;
    }
    if (result.status == ReceiptBatchRunStatus.inputCanceled) {
      return;
    }
    if (result.status == ReceiptBatchRunStatus.inputFailed) {
      _showSnackBar(context, l10n.inventoryReceiptSelectionFailed);
      return;
    }
    if (result.mappedItems.isEmpty) {
      _showSnackBar(context, l10n.inventoryReceiptAnalysisFailed);
      return;
    }

    await _openReviewSheet(
      context: context,
      ref: ref,
      l10n: l10n,
      controller: controller,
      mappedItems: result.mappedItems,
    );
  }

  static Future<void> _openReviewSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ReceiptCaptureFlowController controller,
    required List<FridgeItem> mappedItems,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return InventoryReceiptReviewSheet(
          items: mappedItems,
          onCancelTap: () => Navigator.of(sheetContext).pop(),
          onSaveTap: (reviewedItems) async {
            final saved = await controller.persistReviewedItems(reviewedItems);
            if (!sheetContext.mounted) {
              return;
            }
            Navigator.of(sheetContext).pop();

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
    );
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
