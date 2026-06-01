import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_search_launcher.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Builds the product-search-hub implementation for inventory launch requests.
InventoryManualProductSearchLauncher
buildProductSearchHubManualProductSearchLauncher() {
  return ({required context, required request}) {
    return context.push<InventoryReceiptManualProductResult>(
      AppRoutes.homeProductSearchHub,
      extra: ProductSearchHubRouteArgs.selection(
        item: request.item,
        includeStoreInSearch: request.includeStoreInSearch,
        includeWeightInSearch: request.includeWeightInSearch,
      ),
    );
  };
}
