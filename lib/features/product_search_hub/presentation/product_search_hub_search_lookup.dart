import 'dart:developer' show log;

import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_result_quality.dart';
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

/// Runs product search and applies hub dedupe rules.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubProducts({
  required OffProductSearchRepository repository,
  required String query,
  required int limit,
  String? store,
  String? weight,
}) async {
  try {
    final results = await repository.search(
      query: query,
      limit: limit,
      store: store,
      weight: weight,
    );
    if (results.isNotEmpty) {
      return ProductSearchHubSearchLookupResult.success(
        collapseDominatedOffProductSearchResults(results),
      );
    }
    final normalized = normalizeBarcode(query);
    if (normalized.isNotEmpty && isSupportedBarcode(normalized)) {
      final barcodeResults = await repository.lookupCandidatesByBarcode(
        barcode: normalized,
      );
      if (barcodeResults.isNotEmpty) {
        return ProductSearchHubSearchLookupResult.success(
          collapseDominatedOffProductSearchResults(barcodeResults),
        );
      }
    }
    return ProductSearchHubSearchLookupResult.success(
      collapseDominatedOffProductSearchResults(results),
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

/// Runs product search for a hub route, including route-provided hints.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubRouteProducts({
  required OffProductSearchRepository repository,
  required ProductSearchHubSearchLookup? lookupProducts,
  required ProductSearchHubRouteArgs args,
  required String query,
  required int limit,
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
    query: query,
    limit: limit,
    store: store,
    weight: weight,
  );
}
