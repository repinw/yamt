import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/home/widgets/inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_fab_action_sheet.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows embedded inventory FAB action sheet.
@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
Future<void> showInventoryFabActionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required bool isCameraEnabled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    builder: (sheetContext) {
      return InventoryFabActionSheet(
        isCameraEnabled: isCameraEnabled,
        onProductSearchHub: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.openProductSearchHub(
            context: context,
          ),
        ),
        onManualSearch: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.openManualSearch(
            context: context,
            l10n: l10n,
          ),
        ),
        onBarcodeScan: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.openBarcodeScanner(
            context: context,
            l10n: l10n,
          ),
        ),
        onAiSuggestion: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.openAiSuggestion(
            context: context,
            l10n: l10n,
          ),
        ),
        onUploadFile: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.uploadFile(
            context: context,
            ref: ref,
            l10n: l10n,
          ),
        ),
        onScanCamera: () => _closeAndRun(
          sheetContext,
          () => InventoryActionSheetFlow.scanCamera(
            context: context,
            ref: ref,
            l10n: l10n,
          ),
        ),
      );
    },
  );
}

void _closeAndRun(
  BuildContext sheetContext,
  Future<void> Function() action,
) {
  sheetContext.pop();
  unawaited(action());
}
