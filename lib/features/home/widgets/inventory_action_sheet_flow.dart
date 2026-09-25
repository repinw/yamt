import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory action sheet flow.
class InventoryActionSheetFlow {
  const new _();

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
