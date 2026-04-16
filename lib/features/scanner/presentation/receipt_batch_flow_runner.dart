import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_flow_runner.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines receipt batch flow runner.
class ReceiptBatchFlowRunner {
  /// Creates an instance.
  ReceiptBatchFlowRunner({
    required this.context,
    required this.ref,
    required this.l10n,
    required this.onItemsSaved,
  }) : _batchController = ref.read(receiptBatchFlowControllerProvider.notifier),
       _rootNavigator = Navigator.of(context, rootNavigator: true),
       _reviewFlow = ReceiptReviewFlowRunner(
         context: Navigator.of(context, rootNavigator: true).context,
         ref: ref,
         l10n: l10n,
         captureController: ref.read(
           receiptCaptureFlowControllerProvider.notifier,
         ),
       );

  /// The context.
  final BuildContext context;

  /// The ref.
  final WidgetRef ref;

  /// The l10n.
  final AppLocalizations l10n;

  /// The on items saved.
  final VoidCallback onItemsSaved;
  final ReceiptBatchFlowController _batchController;
  final NavigatorState _rootNavigator;
  final ReceiptReviewFlowRunner _reviewFlow;

  ProviderSubscription<ReceiptBatchFlowState>? _subscription;
  Future<void>? _progressDialog;
  bool _isDialogClosed = true;

  /// Run.
  Future<void> run() async {
    await _runWith(() => _batchController.runFileBatch());
  }

  /// Run selections.
  Future<void> runSelections(List<ReceiptInputSelection> selections) async {
    await _runWith(() => _batchController.runSelections(selections));
  }

  Future<void> _runWith(Future<void> Function() runBatch) async {
    _batchController.reset();
    String? feedbackMessage;
    _progressDialog = _openProgressDialog();
    _subscription = _listenForAutoReview();

    try {
      await runBatch();
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
      _reviewFlow.dispose();
      if (feedbackMessage != null && context.mounted) {
        _reviewFlow.showSnackBar(feedbackMessage);
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

    final reviewDrafts = ref
        .read(receiptBatchFlowControllerProvider)
        .reviewDraftsForIndex(index);
    if (reviewDrafts.isEmpty) {
      _batchController.finishReview(index: index, saved: false);
      return;
    }

    var saved = false;
    try {
      saved = await _openReviewPage(reviewDrafts: reviewDrafts);
    } catch (error, stackTrace) {
      log(
        'Receipt review page failed unexpectedly',
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
    final hasReviewDrafts = batchState.reviewDraftsByIndex.values.any(
      (items) => items.isNotEmpty,
    );
    if (!isBatchComplete ||
        batchState.status != ReceiptBatchFlowStatus.completed ||
        !hasReviewDrafts) {
      return l10n.inventoryReceiptAnalysisFailed;
    }
    return null;
  }

  Future<bool> _openReviewPage({
    required List<ReceiptReviewItemDraft> reviewDrafts,
  }) async {
    if (!_rootNavigator.mounted) {
      return false;
    }

    return _reviewFlow.openReviewPage(
      reviewDrafts: reviewDrafts,
      receiptPreviewBytes: null,
      onItemsSaved: onItemsSaved,
    );
  }
}
