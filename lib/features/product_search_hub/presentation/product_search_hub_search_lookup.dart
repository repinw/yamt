import 'package:yamt/features/inventory/data/'
    'global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_context.dart';

export 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart'
    show
        CompositeProductSearchAdapter,
        lookupProductSearchHubProducts,
        productSearchGatewayProvider;
export 'package:yamt/features/product_search_hub/domain/'
    'product_search_gateway.dart'
    show ProductSearchGateway, ProductSearchHubSearchLookupResult;

/// Product search lookup used by the focused hub search route.
typedef ProductSearchHubSearchLookup =
    Future<ProductSearchHubSearchLookupResult> Function({
      required String query,
      required int limit,
      String? store,
      String? weight,
    });

/// Runs product search for a hub route, including route-provided hints.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubRouteProducts({
  required ProductSearchHubRouteArgs args,
  required String query,
  required int limit,
  ProductSearchGateway? gateway,
  OffProductSearchRepository? repository,
  ProductSearchHubSearchLookup? lookupProducts,
  GlobalFoodItemRepository? globalFoodItemRepository,
}) {
  final store = productSearchHubSearchStore(args);
  final weight = productSearchHubSearchWeight(args);
  if (lookupProducts != null) {
    return lookupProducts(
      query: query,
      limit: limit,
      store: store,
      weight: weight,
    );
  }
  if (gateway != null) {
    return gateway.search(
      query: query,
      limit: limit,
      store: store,
      weight: weight,
    );
  }
  if (repository != null) {
    return lookupProductSearchHubProducts(
      repository: repository,
      globalFoodItemRepository: globalFoodItemRepository,
      query: query,
      limit: limit,
      store: store,
      weight: weight,
    );
  }
  return Future.value(const ProductSearchHubSearchLookupResult.failed());
}
