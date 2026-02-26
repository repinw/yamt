import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ReceiptBatchFlowRunner {
  ReceiptBatchFlowRunner({
    required this.context,
    required this.ref,
    required this.l10n,
    required this.onItemsSaved,
  }) : _captureController = ref.read(
         receiptCaptureFlowControllerProvider.notifier,
       ),
       _batchController = ref.read(receiptBatchFlowControllerProvider.notifier),
       _rootNavigator = Navigator.of(context, rootNavigator: true);

  final BuildContext context;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final VoidCallback onItemsSaved;
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
        name: 'ReceiptBatchFlowRunner',
        error: error,
        stackTrace: stackTrace,
      );
      feedbackMessage = l10n.inventoryReceiptAnalysisFailed;
    } finally {
      await _closeProgressDialog();
      _subscription?.close();
      _batchController.reset();
      if (feedbackMessage != null && context.mounted) {
        _showSnackBar(feedbackMessage);
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
      saved = await _openReviewSheet(mappedItems: mappedItems);
    } catch (error, stackTrace) {
      log(
        'Receipt review sheet failed unexpectedly',
        name: 'ReceiptBatchFlowRunner',
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

  Future<bool> _openReviewSheet({required List<FridgeItem> mappedItems}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return InventoryReceiptReviewSheet(
          items: mappedItems,
          onCancelTap: () => Navigator.of(sheetContext).pop(false),
          onSaveTap: (reviewedItems) async {
            final saved = await _captureController.persistReviewedItems(
              reviewedItems,
            );
            if (!sheetContext.mounted) {
              return;
            }
            Navigator.of(sheetContext).pop(saved);

            if (!context.mounted) {
              return;
            }

            if (saved) {
              onItemsSaved();
              _showSnackBar(l10n.inventoryReceiptSaveSucceeded);
              return;
            }
            _showSnackBar(l10n.inventoryReceiptSaveFailed);
          },
        );
      },
    ).then((saved) => saved ?? false);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
