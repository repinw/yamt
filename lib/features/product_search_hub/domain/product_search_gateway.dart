import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';

/// Search lookup result for the product search hub.
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

/// Abstract gateway for searching products from multiple sources (OFF, local/global food items).
abstract interface class ProductSearchGateway {
  /// Searches candidate products matching [query].
  Future<ProductSearchHubSearchLookupResult> search({
    required String query,
    required int limit,
    String? store,
    String? brand,
    String? weight,
  });

  /// Resolves barcode candidates from learned history and Open Food Facts.
  Future<List<InventoryBarcodeLookupCandidate>> resolveBarcodeCandidates({
    required String barcode,
  });
}
