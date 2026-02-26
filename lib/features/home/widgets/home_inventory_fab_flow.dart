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
    final runner = _HomeInventoryBatchFlowRunner(
      context: context,
      ref: ref,
      l10n: l10n,
    );
    await runner.run();
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

class _HomeInventoryBatchFlowRunner {
  _HomeInventoryBatchFlowRunner({
    required this.context,
    required this.ref,
    required this.l10n,
  }) : _captureController = ref.read(
         receiptCaptureFlowControllerProvider.notifier,
       ),
       _batchController = ref.read(receiptBatchFlowControllerProvider.notifier),
       _rootNavigator = Navigator.of(context, rootNavigator: true);

  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final ReceiptCaptureFlowController _captureController;
  final ReceiptBatchFlowController _batchController;
  final NavigatorState _rootNavigator;

  ProviderSubscription<ReceiptBatchFlowState>? _subscription;
  Future<void>? _progressDialog;
  bool _isDialogClosed = true;

  Future<void> run() async {
    _batchController.reset();
    String? feedbackMessage;
    _progressDialog = _openProgressDialog();
    _subscription = _listenForAutoReview();

    try {
      await _batchController.runFileBatch();
      if (!context.mounted) {
        return;
      }

      final batchState = ref.read(receiptBatchFlowControllerProvider);
      feedbackMessage = _feedbackMessageFor(batchState);
      if (feedbackMessage == null &&
          batchState.status == ReceiptBatchFlowStatus.completed) {
        final dialog = _progressDialog;
        if (dialog != null) {
          await dialog;
        }
      }
    } catch (error, stackTrace) {
      log(
        'Receipt batch flow failed unexpectedly',
        name: 'HomeInventoryFabFlow',
        error: error,
        stackTrace: stackTrace,
      );
      feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
    } finally {
      await _closeProgressDialog();
      _subscription?.close();
      _batchController.reset();
      if (feedbackMessage != null && context.mounted) {
        HomeInventoryFabFlow._showSnackBar(context, feedbackMessage);
      }
    }
  }

  ProviderSubscription<ReceiptBatchFlowState> _listenForAutoReview() {
    return ref.listenManual(receiptBatchFlowControllerProvider, (
      previous,
      next,
    ) {
      final pendingIndex = next.pendingAutoReviewIndex;
      if (pendingIndex == null || next.isReviewOpen || !context.mounted) {
        return;
      }
      _batchController.consumePendingAutoReview();
      unawaited(_openReviewForIndex(pendingIndex));
    }, fireImmediately: true);
  }

  Future<void> _openReviewForIndex(int index) async {
    if (!context.mounted || !_batchController.startReview(index)) {
      return;
    }

    final mappedItems = ref
        .read(receiptBatchFlowControllerProvider)
        .mappedItemsForIndex(index);
    if (mappedItems.isEmpty) {
      _batchController.finishReview(index: index, saved: false);
      return;
    }

    var saved = false;
    try {
      saved = await HomeInventoryFabFlow._openReviewSheet(
        context: context,
        ref: ref,
        l10n: l10n,
        controller: _captureController,
        mappedItems: mappedItems,
      );
    } catch (error, stackTrace) {
      log(
        'Receipt review sheet failed unexpectedly',
        name: 'HomeInventoryFabFlow',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _batchController.finishReview(index: index, saved: saved);
    }
  }

  Future<void> _openProgressDialog() {
    _isDialogClosed = false;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return InventoryReceiptBatchProgressDialog(
          onReviewTap: _openReviewForIndex,
          onCloseTap: () {
            if (_rootNavigator.mounted) {
              _rootNavigator.pop();
            }
          },
        );
      },
    ).whenComplete(() {
      _isDialogClosed = true;
    });
  }

  Future<void> _closeProgressDialog() async {
    if (!_isDialogClosed && _rootNavigator.mounted) {
      _rootNavigator.pop();
    }
    final dialog = _progressDialog;
    if (dialog != null) {
      await dialog;
    }
  }

  String? _feedbackMessageFor(ReceiptBatchFlowState batchState) {
    if (batchState.status == ReceiptBatchFlowStatus.inputCanceled) {
      return null;
    }
    if (batchState.status == ReceiptBatchFlowStatus.inputFailed) {
      return l10n.inventoryReceiptSelectionFailed;
    }

    final progress = batchState.progress;
    final isBatchComplete =
        progress.totalCount == 0 ||
        progress.processedCount == progress.totalCount;
    final hasMappedItems = batchState.mappedItemsByIndex.values.any(
      (items) => items.isNotEmpty,
    );
    if (!isBatchComplete ||
        batchState.status != ReceiptBatchFlowStatus.completed ||
        !hasMappedItems) {
      return l10n.inventoryReceiptAnalysisFailed;
    }
    return null;
  }
}
