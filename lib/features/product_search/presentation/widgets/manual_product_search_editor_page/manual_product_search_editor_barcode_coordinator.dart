import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_barcode_context.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_navigation.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the barcode scanner bottom sheet and processes the resulting
/// selection.
Future<void> openEditorBarcodeScanner({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required bool showEatImmediatelyOption,
  required bool autofocusSearch,
  required Future<void> Function() onStopVoiceSearch,
  required void Function(InventoryReceiptManualProductResult result)
  onDirectComplete,
  required void Function(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  )
  onApplyScannedProduct,
  required void Function(
    InventoryItem item,
    InventoryReceiptManualProductAction action,
  )
  onApplyScannedInventoryItem,
  required void Function(String barcode) onApplyScannedBarcodeOnly,
  required void Function(String message) onShowSnackBar,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) async {
  await onStopVoiceSearch();
  if (!context.mounted) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final result = await showModalBottomSheet<ManualBarcodeScanResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 1,
      child: InventoryBarcodeScannerPage(
        title: l10n.inventoryManualAddScanBarcodeAction,
        showActionButtons: showEatImmediatelyOption,
        onProductSelected: (candidate, scannedBarcode, action) async {
          sheetContext.pop(
            ManualBarcodeScanResult.selected(
              candidate: candidate,
              scannedBarcode: scannedBarcode,
              action: action,
            ),
          );
          return true;
        },
        onProductNotFound: (scannedBarcode) async {
          sheetContext.pop(
            ManualBarcodeScanResult.notFound(scannedBarcode: scannedBarcode),
          );
          return true;
        },
        onCreateManualProduct: (scannedBarcode) async {
          sheetContext.pop(
            ManualBarcodeScanResult.manual(scannedBarcode: scannedBarcode),
          );
          return true;
        },
        eatOnly: quickEatConfig.quickEatOnly,
      ),
    ),
  );
  if (!context.mounted || result == null) {
    return;
  }

  final dispatchContext = EditorBarcodeDispatchContext(
    context: context,
    config: config,
    controller: controller,
    showEatImmediatelyOption: showEatImmediatelyOption,
    autofocusSearch: autofocusSearch,
    quickEatConfig: quickEatConfig,
    onDirectComplete: onDirectComplete,
    onApplyScannedProduct: onApplyScannedProduct,
    onApplyScannedInventoryItem: onApplyScannedInventoryItem,
    onApplyScannedBarcodeOnly: onApplyScannedBarcodeOnly,
    onShowSnackBar: onShowSnackBar,
    onSaved: onSaved,
    onClosePage: onClosePage,
  );
  await _dispatchBarcodeScanResult(dispatchContext, result);
}

Future<void> _dispatchBarcodeScanResult(
  EditorBarcodeDispatchContext ctx,
  ManualBarcodeScanResult result,
) async {
  switch (result.kind) {
    case ManualBarcodeScanResultKind.selected:
      await _handleSelectedBarcodeCandidate(ctx, result);
    case ManualBarcodeScanResultKind.notFound:
      _handleBarcodeNotFound(ctx, result.scannedBarcode);
    case ManualBarcodeScanResultKind.manual:
      _handleBarcodeManual(ctx, result.scannedBarcode);
  }
}

Future<void> _handleSelectedBarcodeCandidate(
  EditorBarcodeDispatchContext ctx,
  ManualBarcodeScanResult result,
) async {
  final candidate = result.candidate;
  if (candidate == null) {
    return;
  }
  final action = manualProductActionFromBarcodeAction(result.action);
  final externalProduct = candidate.externalProduct;
  if (externalProduct != null) {
    await _handleScannedExternalProduct(ctx, externalProduct, action);
    return;
  }

  final globalFoodItem = candidate.globalFoodItem;
  if (globalFoodItem != null) {
    _handleScannedGlobalFoodItem(
      ctx,
      candidate: candidate,
      globalFoodItem: globalFoodItem,
      action: action,
      scannedBarcode: result.scannedBarcode,
    );
  }
}

Future<void> _handleScannedExternalProduct(
  EditorBarcodeDispatchContext ctx,
  OffProductSearchResult product,
  InventoryReceiptManualProductAction action,
) async {
  if (action == InventoryReceiptManualProductAction.eatNow) {
    final directEat = tryBuildDirectEatResultFromSearchResult(
      product: product,
      controller: ctx.controller,
    );
    if (directEat != null) {
      ctx.onDirectComplete(directEat);
      return;
    }
  }

  if (ctx.autofocusSearch || ctx.quickEatConfig.quickEatOnly) {
    await openSelectedProductEditor(
      context: ctx.context,
      quickEatConfig: ctx.quickEatConfig,
      parentConfig: ctx.config,
      product: product,
      action: action,
      showEatImmediatelyOption: ctx.showEatImmediatelyOption,
      showActionSelector: false,
      initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
          ? AppLocalizations.of(
              ctx.context,
            )!.inventoryManualAddEatNowRequiresNutrition
          : null,
      onSaved: ctx.onSaved,
      onClosePage: ctx.onClosePage,
    );
    return;
  }

  ctx.onApplyScannedProduct(product, action);
}

void _handleScannedGlobalFoodItem(
  EditorBarcodeDispatchContext ctx, {
  required InventoryBarcodeLookupCandidate candidate,
  required GlobalFoodItem globalFoodItem,
  required InventoryReceiptManualProductAction action,
  required String? scannedBarcode,
}) {
  final selectedItem = inventoryItemFromBarcodeCandidate(
    baseItem: ctx.config.item,
    globalFoodItem: globalFoodItem,
    barcode: scannedBarcode ?? candidate.barcode,
  );
  if (action == InventoryReceiptManualProductAction.eatNow) {
    final directEat = tryBuildDirectEatResultFromInventoryItem(
      item: selectedItem,
      selectedGlobalFoodItemId: candidate.globalFoodItemId,
      globalPackageWeight: candidate.packageWeight,
    );
    if (directEat != null) {
      ctx.onDirectComplete(directEat);
      return;
    }
  }
  ctx.onApplyScannedInventoryItem(selectedItem, action);
}

void _handleBarcodeNotFound(
  EditorBarcodeDispatchContext ctx,
  String? scannedBarcode,
) {
  if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
    ctx.onApplyScannedBarcodeOnly(scannedBarcode);
    ctx.onShowSnackBar(
      AppLocalizations.of(ctx.context)!.inventoryManualAddNotFound,
    );
  }
}

void _handleBarcodeManual(
  EditorBarcodeDispatchContext ctx,
  String? scannedBarcode,
) {
  if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
    ctx.onApplyScannedBarcodeOnly(scannedBarcode);
  }
}
