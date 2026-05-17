import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_search_launcher.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';

/// Builds the product-search implementation for inventory launch requests.
InventoryManualProductSearchLauncher
buildProductSearchManualProductSearchLauncher() {
  return ({required context, required request}) {
    return pushManualProductSearchPage<InventoryReceiptManualProductResult>(
      context: context,
      args: ManualProductSearchRouteArgs.manualProduct(
        item: request.item,
        includeStoreInSearch: request.includeStoreInSearch,
        includeWeightInSearch: request.includeWeightInSearch,
      ),
    );
  };
}
