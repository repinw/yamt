import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_direct_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_scanner.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Edited barcode product result plus stable source key.
class ProductSearchHubBarcodeFlowResult {
  /// Creates barcode flow result.
  const ProductSearchHubBarcodeFlowResult({
    required this.sourceKey,
    required this.result,
  });

  /// Key used to mark the source as already selected.
  final String sourceKey;

  /// Edited manual product result.
  final InventoryReceiptManualProductResult result;
}

/// Whether barcode editor should explain missing nutrition for diary eat flow.
bool productSearchHubBarcodeNeedsEatNutritionMessage({
  required ProductSearchHubRouteArgs args,
  required GlobalFoodNutrition? nutrition,
}) {
  return args.mode == ProductSearchHubMode.diary &&
      !hasRequiredEatNowNutrition(nutrition);
}

/// Opens barcode scanner and returns an edited product result.
Future<ProductSearchHubBarcodeFlowResult?> openProductSearchHubBarcodeFlow({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await openProductSearchHubBarcodeScanner(
    context: context,
    args: args,
  );
  if (!context.mounted || result == null) {
    return null;
  }
  return _openEditorForBarcodeResult(
    context: context,
    l10n: l10n,
    draftItem: draftItem,
    args: args,
    result: result,
  );
}

Future<ProductSearchHubBarcodeFlowResult?> _openEditorForBarcodeResult({
  required BuildContext context,
  required AppLocalizations l10n,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  required ManualBarcodeScanResult result,
}) async {
  return switch (result.kind) {
    ManualBarcodeScanResultKind.selected => _openSelectedCandidateEditor(
      context: context,
      draftItem: draftItem,
      args: args,
      result: result,
    ),
    ManualBarcodeScanResultKind.notFound => _openManualBarcodeEditor(
      context: context,
      draftItem: draftItem,
      args: args,
      scannedBarcode: result.scannedBarcode,
      initialInfoMessage: l10n.inventoryManualAddNotFound,
    ),
    ManualBarcodeScanResultKind.manual => _openManualBarcodeEditor(
      context: context,
      draftItem: draftItem,
      args: args,
      scannedBarcode: result.scannedBarcode,
    ),
  };
}

Future<ProductSearchHubBarcodeFlowResult?> _openSelectedCandidateEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  required ManualBarcodeScanResult result,
}) async {
  final candidate = result.candidate;
  if (candidate == null) {
    return null;
  }
  final sourceKey = result.scannedBarcode ?? candidate.barcode;
  final action = manualProductActionFromBarcodeAction(result.action);
  final selectedProduct = candidate.externalProduct;
  if (selectedProduct != null) {
    final directResult = productSearchHubDirectBarcodeProductResult(
      container: ProviderScope.containerOf(context, listen: false),
      draftItem: draftItem,
      args: args,
      product: selectedProduct,
      action: action,
    );
    if (directResult != null) {
      return ProductSearchHubBarcodeFlowResult(
        sourceKey: sourceKey,
        result: directResult,
      );
    }
    final editedResult = await openProductSearchHubSelectedProductEditor(
      context: context,
      draftItem: draftItem,
      product: selectedProduct,
      args: args,
      initialInfoMessage: _eatNutritionMessage(
        l10n: AppLocalizations.of(context)!,
        args: args,
        nutrition: selectedProduct.nutrition,
      ),
    );
    return _barcodeResult(sourceKey, editedResult);
  }

  final globalFoodItem = candidate.globalFoodItem;
  if (globalFoodItem == null) {
    return null;
  }
  final selectedItem = inventoryItemFromBarcodeCandidate(
    baseItem: draftItem,
    globalFoodItem: globalFoodItem,
    barcode: result.scannedBarcode ?? candidate.barcode,
  );
  final directResult = productSearchHubDirectBarcodeInventoryItemResult(
    args: args,
    item: selectedItem,
    action: action,
    selectedGlobalFoodItemId: candidate.globalFoodItemId,
    globalPackageWeight: candidate.packageWeight,
  );
  if (directResult != null) {
    return ProductSearchHubBarcodeFlowResult(
      sourceKey: sourceKey,
      result: directResult,
    );
  }
  final editedResult = await openProductSearchHubRecentItemEditor(
    context: context,
    draftItem: selectedItem,
    recentItem: selectedItem,
    args: args,
    initialInfoMessage: _eatNutritionMessage(
      l10n: AppLocalizations.of(context)!,
      args: args,
      nutrition: selectedItem.nutrition,
    ),
  );
  return _barcodeResult(sourceKey, editedResult);
}

Future<ProductSearchHubBarcodeFlowResult?> _openManualBarcodeEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  required String? scannedBarcode,
  String? initialInfoMessage,
}) async {
  if (scannedBarcode == null || scannedBarcode.isEmpty) {
    return null;
  }
  final editedResult = await openProductSearchHubCustomProductEditor(
    context: context,
    draftItem: draftItem,
    args: args,
    scannedBarcode: scannedBarcode,
    initialInfoMessage: initialInfoMessage,
  );
  return _barcodeResult(scannedBarcode, editedResult);
}

String? _eatNutritionMessage({
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required GlobalFoodNutrition? nutrition,
}) {
  final needsMessage = productSearchHubBarcodeNeedsEatNutritionMessage(
    args: args,
    nutrition: nutrition,
  );
  return needsMessage ? l10n.inventoryManualAddEatNowRequiresNutrition : null;
}

ProductSearchHubBarcodeFlowResult? _barcodeResult(
  String sourceKey,
  InventoryReceiptManualProductResult? result,
) {
  if (result == null) {
    return null;
  }
  return ProductSearchHubBarcodeFlowResult(
    sourceKey: sourceKey,
    result: result,
  );
}
