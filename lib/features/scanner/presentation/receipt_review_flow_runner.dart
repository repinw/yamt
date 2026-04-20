import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines receipt review flow runner.
@Dependencies([ReceiptCaptureFlowController])
class ReceiptReviewFlowRunner {
  /// Creates an instance.
  ReceiptReviewFlowRunner({
    required this.context,
    required this.ref,
    required this.l10n,
    ReceiptCaptureFlowController? captureController,
  }) : _captureController =
           captureController ??
           ref.read(receiptCaptureFlowControllerProvider.notifier),
       _captureFlowSubscription = ref.listenManual(
         receiptCaptureFlowControllerProvider,
         (_, _) {},
       ),
       _rootNavigator = Navigator.of(context, rootNavigator: true);

  /// The context.
  final BuildContext context;

  /// The ref.
  final WidgetRef ref;

  /// The l10n.
  final AppLocalizations l10n;
  final ReceiptCaptureFlowController _captureController;
  final ProviderSubscription<AsyncValue<ReceiptCaptureFlowResult?>>
  _captureFlowSubscription;
  final NavigatorState _rootNavigator;

  /// Dispose.
  void dispose() {
    _captureFlowSubscription.close();
  }

  /// Handle capture result.
  Future<void> handleCaptureResult({
    required ReceiptCaptureFlowResult result,
    required VoidCallback onItemsSaved,
  }) async {
    if (result.status == ReceiptCaptureFlowStatus.completed) {
      await openReviewPage(
        reviewDrafts: result.reviewDrafts ?? const <ReceiptReviewItemDraft>[],
        receiptPreviewBytes: result.receiptPreviewBytes,
        onItemsSaved: onItemsSaved,
      );
      return;
    }

    final message = feedbackMessageFor(result);
    if (message != null) {
      showSnackBar(message);
    }
  }

  /// Run selection.
  Future<void> runSelection({
    required ReceiptInputSelection selection,
    required VoidCallback onItemsSaved,
  }) async {
    if (!_rootNavigator.mounted) {
      return;
    }

    var loadingDialogOpen = true;
    final loadingDialog =
        showDialog<void>(
          context: _rootNavigator.context,
          barrierDismissible: false,
          builder: (_) {
            return const Center(child: CircularProgressIndicator());
          },
        ).whenComplete(() {
          loadingDialogOpen = false;
        });

    final result = await (() async {
      try {
        return await _captureController.runSelection(selection: selection);
      } finally {
        if (loadingDialogOpen && _rootNavigator.mounted) {
          _rootNavigator.pop();
        }
        await loadingDialog;
      }
    })();

    if (!context.mounted) {
      return;
    }

    await handleCaptureResult(result: result, onItemsSaved: onItemsSaved);
  }

  /// Open review page.
  Future<bool> openReviewPage({
    required List<ReceiptReviewItemDraft> reviewDrafts,
    required Uint8List? receiptPreviewBytes,
    required VoidCallback onItemsSaved,
  }) async {
    if (!_rootNavigator.mounted) {
      return false;
    }

    final saved = await _rootNavigator.context.push<bool>(
      AppRoutes.homeInventoryReceiptReview,
      extra: InventoryReceiptReviewPageArgs(
        items: reviewDrafts,
        receiptPreviewBytes: receiptPreviewBytes,
        onSaveTap: (reviewedItems) async {
          final saved = await _captureController.persistReviewedItems(
            reviewedItems,
          );
          if (!context.mounted) {
            return false;
          }

          if (saved) {
            onItemsSaved();
            showSnackBar(l10n.inventoryReceiptSaveSucceeded);
            return true;
          }

          showSnackBar(l10n.inventoryReceiptSaveFailed);
          return false;
        },
      ),
    );

    return saved ?? false;
  }

  /// Feedback message for.
  String? feedbackMessageFor(ReceiptCaptureFlowResult result) {
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

  /// Show snack bar.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
