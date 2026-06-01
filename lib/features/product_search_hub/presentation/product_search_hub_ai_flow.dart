import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_quick_eat_config.dart';

/// Opens AI product creation from the product search hub.
Future<InventoryReceiptManualProductResult?> openProductSearchHubAiFlow({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  String initialPrompt = '',
}) async {
  final result = await pushManualProductSearchPage<ManualProductAiSearchResult>(
    context: context,
    args: ManualProductSearchRouteArgs.aiSearch(
      item: draftItem,
      initialPrompt: initialPrompt,
      showEatImmediatelyOption: args.mode == ProductSearchHubMode.diary,
      initialAction: _initialActionForMode(args.mode),
      quickEatConfig: productSearchHubQuickEatConfig(args),
    ),
  );
  if (result == null) {
    return null;
  }
  return InventoryReceiptManualProductResult(
    item: result.item,
    action: result.action,
    globalPackageWeight: result.globalPackageWeight,
    skipMissingBarcodePrompt: true,
    eatSelection: result.eatSelection,
  );
}

InventoryReceiptManualProductAction _initialActionForMode(
  ProductSearchHubMode mode,
) {
  return switch (mode) {
    ProductSearchHubMode.inventory =>
      InventoryReceiptManualProductAction.addToInventory,
    ProductSearchHubMode.selection =>
      InventoryReceiptManualProductAction.addToInventory,
    ProductSearchHubMode.diary => InventoryReceiptManualProductAction.eatNow,
  };
}
