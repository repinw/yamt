import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/scanner/presentation/widgets/inventory_receipt_actions_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory action sheet flow.
@Dependencies([
  InventoryItemsController,
  receiptScanFlowCoordinator,
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

  /// Scan receipt with camera using the rebuilt scanner flow.
  static Future<void> scanCamera({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final coordinator = ref.read(receiptScanFlowCoordinatorProvider);
    final saved = await coordinator.startCameraFlow(context);
    if (saved) {
      ref.invalidate(inventoryItemsControllerProvider);
    }
  }

  /// Upload receipt file (PDF / images) using the rebuilt scanner flow.
  static Future<void> uploadFile({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final coordinator = ref.read(receiptScanFlowCoordinatorProvider);
    final saved = await coordinator.startFilePickerFlow(context);
    if (saved) {
      ref.invalidate(inventoryItemsControllerProvider);
    }
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
            unawaited(scanCamera(context: context, ref: ref, l10n: l10n));
          },
          onUploadFileTap: () {
            sheetContext.pop();
            unawaited(uploadFile(context: context, ref: ref, l10n: l10n));
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
}
