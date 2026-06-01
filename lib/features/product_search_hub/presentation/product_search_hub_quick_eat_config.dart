import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Builds product-search child quick-eat config for the hub mode.
InventoryManualAddQuickEatConfig productSearchHubQuickEatConfig(
  ProductSearchHubRouteArgs args,
) {
  return InventoryManualAddQuickEatConfig(
    quickEatOnly: args.mode == ProductSearchHubMode.diary,
    preselectedMealType: args.preselectedMealType,
    preselectedLoggedAt: args.preselectedLoggedAt,
  );
}
