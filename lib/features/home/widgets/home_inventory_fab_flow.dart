import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/presentation/receipt_batch_flow_runner.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_actions_sheet.dart';
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
      await _openReviewPage(
        context: context,
        ref: ref,
        l10n: l10n,
        controller: controller,
        reviewDrafts: result.reviewDrafts ?? const <ReceiptReviewItemDraft>[],
        receiptPreviewBytes: result.receiptPreviewBytes,
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
    final runner = ReceiptBatchFlowRunner(
      context: context,
      ref: ref,
      l10n: l10n,
      onItemsSaved: () => ref.invalidate(inventoryItemsControllerProvider),
    );
    await runner.run();
  }

  static Future<bool> _openReviewPage({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ReceiptCaptureFlowController controller,
    required List<ReceiptReviewItemDraft> reviewDrafts,
    required Uint8List? receiptPreviewBytes,
  }) async {
    final saved = await context.push<bool>(
      AppRoutes.homeInventoryReceiptReview,
      extra: InventoryReceiptReviewPageArgs(
        items: reviewDrafts,
        receiptPreviewBytes: receiptPreviewBytes,
        onSaveTap: (reviewedItems) async {
          final saved = await controller.persistReviewedItems(reviewedItems);
          if (!context.mounted) {
            return false;
          }

          if (saved) {
            ref.invalidate(inventoryItemsControllerProvider);
            _showSnackBar(context, l10n.inventoryReceiptSaveSucceeded);
            return true;
          }

          _showSnackBar(context, l10n.inventoryReceiptSaveFailed);
          return false;
        },
      ),
    );

    return saved ?? false;
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
