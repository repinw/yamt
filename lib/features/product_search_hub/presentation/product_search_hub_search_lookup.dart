import 'dart:developer' show log;

import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_context.dart';

const _productSearchHubSearchLogName = 'ProductSearchHubSearchPage';

/// Product search lookup used by the focused hub search route.
typedef ProductSearchHubSearchLookup =
    Future<ProductSearchHubSearchLookupResult> Function({
      required String query,
      required int limit,
      String? store,
      String? weight,
    });

/// Search lookup result for the focused hub search page.
class ProductSearchHubSearchLookupResult {
  const ProductSearchHubSearchLookupResult._({
    required this.results,
    required this.hasFailed,
  });

  /// Successful lookup.
  factory ProductSearchHubSearchLookupResult.success(
    List<OffProductSearchResult> results,
  ) {
    return ProductSearchHubSearchLookupResult._(
      results: results,
      hasFailed: false,
    );
  }

  /// Failed lookup.
  const ProductSearchHubSearchLookupResult.failed()
    : this._(results: const <OffProductSearchResult>[], hasFailed: true);

  /// Visible results.
  final List<OffProductSearchResult> results;

  /// Whether lookup failed.
  final bool hasFailed;
}

/// Runs product search and applies hub dedupe rules across Firebase and OFF.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubProducts({
  required OffProductSearchRepository repository,
  required String query,
  required int limit,
  GlobalFoodItemRepository? globalFoodItemRepository,
  String? store,
  String? weight,
}) async {
  try {
    final normalized = normalizeBarcode(query);
    final isBarcode = normalized.isNotEmpty && isSupportedBarcode(normalized);

    final resultsList = await Future.wait([
      _lookupGlobalFoodItems(
        repository: globalFoodItemRepository,
        query: query,
        barcode: isBarcode ? normalized : null,
        store: store,
        limit: limit,
      ),
      _lookupOffProducts(
        repository: repository,
        query: query,
        barcode: isBarcode ? normalized : null,
        store: store,
        weight: weight,
        limit: limit,
      ),
    ]);

    final globalResults = resultsList[0];
    final offResults = resultsList[1];
    final combined = <OffProductSearchResult>[
      ...globalResults,
      ...offResults,
    ];

    return ProductSearchHubSearchLookupResult.success(
      collapseDominatedOffProductSearchResults(combined),
    );
  } on Object catch (error, stackTrace) {
    log(
      'Product search hub search failed for query "$query".',
      name: _productSearchHubSearchLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const ProductSearchHubSearchLookupResult.failed();
  }
}

Future<List<OffProductSearchResult>> _lookupGlobalFoodItems({
  required GlobalFoodItemRepository? repository,
  required String query,
  required String? barcode,
  required String? store,
  required int limit,
}) async {
  if (repository == null) {
    return const <OffProductSearchResult>[];
  }
  try {
    final items = barcode != null
        ? await repository.searchCandidates(
            barcode: barcode,
            limit: limit,
          )
        : await repository.searchCandidates(
            normalizedName: normalizeGlobalFoodText(query),
            normalizedStoreName:
                store != null ? normalizeGlobalFoodText(store) : null,
            searchTokens: buildGlobalFoodSearchTokens(name: query),
            limit: limit,
          );
    return items
        .map(OffProductSearchResult.fromGlobalFoodItem)
        .toList(growable: false);
  } on Object catch (error, stackTrace) {
    log(
      'Global food item search failed for query "$query".',
      name: _productSearchHubSearchLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <OffProductSearchResult>[];
  }
}

Future<List<OffProductSearchResult>> _lookupOffProducts({
  required OffProductSearchRepository repository,
  required String query,
  required String? barcode,
  required String? store,
  required String? weight,
  required int limit,
}) async {
  try {
    final results = await repository.search(
      query: query,
      limit: limit,
      store: store,
      weight: weight,
    );
    if (results.isNotEmpty) {
      return results;
    }
    if (barcode != null) {
      return await repository.lookupCandidatesByBarcode(barcode: barcode);
    }
    return results;
  } on Object catch (error, stackTrace) {
    log(
      'Open Food Facts search failed for query "$query".',
      name: _productSearchHubSearchLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <OffProductSearchResult>[];
  }
}

/// Runs product search for a hub route, including route-provided hints.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubRouteProducts({
  required OffProductSearchRepository repository,
  required ProductSearchHubSearchLookup? lookupProducts,
  required ProductSearchHubRouteArgs args,
  required String query,
  required int limit,
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
  return lookupProductSearchHubProducts(
    repository: repository,
    globalFoodItemRepository: globalFoodItemRepository,
    query: query,
    limit: limit,
    store: store,
    weight: weight,
  );
}
