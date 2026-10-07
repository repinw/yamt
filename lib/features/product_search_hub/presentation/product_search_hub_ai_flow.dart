import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';

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
      // The Vorrat's own add sheet offers eating instead, too.
      showEatImmediatelyOption: args.isDiary || args.offersEatInstead,
      initialAction: args.initialManualProductAction,
      quickEatConfig: productSearchHubQuickEatConfig(args),
    ),
  );
  return result == null ? null : productSearchHubAiResult(result);
}

/// Turns the result of the AI page into a product search hub result.
InventoryReceiptManualProductResult productSearchHubAiResult(
  ManualProductAiSearchResult result,
) {
  return InventoryReceiptManualProductResult(
    item: result.item,
    action: result.action,
    globalPackageWeight: result.globalPackageWeight,
    skipMissingBarcodePrompt: true,
    // The AI page has its own "In Vorrat" and eat buttons.
    confirmed: true,
    eatSelection: result.eatSelection,
    eatRequest: result.eatRequest,
  );
}
