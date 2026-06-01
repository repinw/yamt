import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/receipt_batch_flow_runner.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_flow_runner.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_actions_sheet.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory action sheet flow.
@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
class InventoryActionSheetFlow {
  const InventoryActionSheetFlow._();

  /// Open manual search.
  static Future<void> openManualSearch({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    return _openProductSearchHub(
      context,
      initialIntent: ProductSearchHubInitialIntent.search,
    );
  }

  /// Open AI suggestion.
  static Future<void> openAiSuggestion({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    return _openProductSearchHub(
      context,
      initialIntent: ProductSearchHubInitialIntent.ai,
    );
  }

  /// Open barcode scanner.
  static Future<void> openBarcodeScanner({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    return _openProductSearchHub(
      context,
      initialIntent: ProductSearchHubInitialIntent.barcode,
    );
  }

  /// Scan receipt with camera.
  static Future<void> scanCamera({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    return _runFlow(context, ref, l10n, ReceiptInputSource.camera);
  }

  /// Upload receipt file.
  static Future<void> uploadFile({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    return _runBatchFlow(context, ref, l10n);
  }

  /// Open product search hub.
  static Future<void> openProductSearchHub({
    required BuildContext context,
  }) async {
    await _openProductSearchHub(context);
  }

  /// Open action sheet.
  static Future<void> openActionSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) {
    final isCameraEnabled = ref.read(receiptCameraSupportedProvider);

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        return InventoryReceiptActionsSheet(
          isCameraEnabled: isCameraEnabled,
          onManualAddTap: () {
            sheetContext.pop();
            unawaited(_openProductSearchHub(context));
          },
          onScanCameraTap: () {
            sheetContext.pop();
            unawaited(_runFlow(context, ref, l10n, ReceiptInputSource.camera));
          },
          onUploadFileTap: () {
            sheetContext.pop();
            unawaited(_runBatchFlow(context, ref, l10n));
          },
        );
      },
    );
  }

  static Future<void> _openProductSearchHub(
    BuildContext context, {
    ProductSearchHubInitialIntent initialIntent =
        ProductSearchHubInitialIntent.launcher,
  }) async {
    await context.push<void>(
      AppRoutes.homeProductSearchHub,
      extra: ProductSearchHubRouteArgs.inventory(initialIntent: initialIntent),
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

    final reviewFlow = ReceiptReviewFlowRunner(
      context: context,
      ref: ref,
      l10n: l10n,
      captureController: controller,
    );
    try {
      await reviewFlow.handleCaptureResult(
        result: result,
        onItemsSaved: () => ref.invalidate(inventoryItemsControllerProvider),
      );
    } finally {
      reviewFlow.dispose();
    }
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
}
