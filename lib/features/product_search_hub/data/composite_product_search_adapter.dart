import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_gateway.dart';

part 'composite_product_search_adapter.g.dart';

const _productSearchHubSearchLogName = 'ProductSearchHubSearchPage';

/// Provides the composite search adapter as a [ProductSearchGateway].
@riverpod
ProductSearchGateway productSearchGateway(Ref ref) {
  return CompositeProductSearchAdapter(
    offRepository: ref.watch(offProductSearchRepositoryProvider),
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    barcodeCandidateRepository: ref.watch(
      globalBarcodeCandidateRepositoryProvider,
    ),
    recentItemsService: ref.watch(manualProductRecentItemsServiceProvider),
  );
}

/// Adapter combining Firebase global food items and Open Food Facts.
class CompositeProductSearchAdapter implements ProductSearchGateway {
  /// Creates a composite product search adapter.
  const new({
    required this._offRepository,
    this._globalFoodItemRepository,
    this._barcodeCandidateRepository,
    this._recentItemsService,
  });

  final OffProductSearchRepository _offRepository;
  final GlobalFoodItemRepository? _globalFoodItemRepository;
  final GlobalBarcodeCandidateRepository? _barcodeCandidateRepository;
  final ManualProductRecentItemsService? _recentItemsService;

  @override
  Future<ProductSearchHubSearchLookupResult> search({
    required String query,
    required int limit,
    String? store,
    String? brand,
    String? weight,
  }) {
    return lookupProductSearchHubProducts(
      repository: _offRepository,
      globalFoodItemRepository: _globalFoodItemRepository,
      query: query,
      limit: limit,
      store: store,
      brand: brand,
      weight: weight,
    );
  }

  @override
  Future<List<InventoryBarcodeLookupCandidate>> resolveBarcodeCandidates({
    required String barcode,
  }) async {
    final learnedCandidatesFuture = _readLearnedCandidates(barcode);
    final offCandidatesFuture = _readOffCandidates(barcode);
    final learnedCandidates = await learnedCandidatesFuture;
    final offCandidates = await offCandidatesFuture;
    return mergeInventoryBarcodeCandidates(
      learnedCandidates: learnedCandidates,
      offCandidates: offCandidates,
    );
  }

  @override
  Future<List<InventoryItem>> readRecentItems() async {
    final service = _recentItemsService;
    if (service == null) {
      return const <InventoryItem>[];
    }
    return await service.readRecentItems();
  }

  Future<List<GlobalBarcodeCandidate>> _readLearnedCandidates(
    String barcode,
  ) async {
    final repository = _barcodeCandidateRepository;
    if (repository == null) {
      return const <GlobalBarcodeCandidate>[];
    }
    try {
      return await repository.readCandidates(barcode: barcode);
    } on Object catch (error, stackTrace) {
      log(
        'Learned barcode candidate lookup failed for $barcode.',
        name: _productSearchHubSearchLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalBarcodeCandidate>[];
    }
  }

  Future<List<OffProductSearchResult>> _readOffCandidates(
    String barcode,
  ) async {
    try {
      return await _offRepository.lookupCandidatesByBarcode(barcode: barcode);
    } on Object catch (error, stackTrace) {
      log(
        'OFF barcode candidate lookup failed for $barcode.',
        name: _productSearchHubSearchLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <OffProductSearchResult>[];
    }
  }
}

/// Runs product search and applies hub dedupe rules across Firebase and OFF.
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubProducts({
  required OffProductSearchRepository repository,
  required String query,
  required int limit,
  GlobalFoodItemRepository? globalFoodItemRepository,
  String? store,
  String? brand,
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
        brand: brand,
        weight: weight,
        limit: limit,
      ),
    ]);

    final globalResults = resultsList[0];
    final offResults = resultsList[1];
    final combined = <OffProductSearchResult>[...globalResults, ...offResults];

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
        ? await repository.searchCandidates(barcode: barcode, limit: limit)
        : await repository.searchCandidates(
            normalizedName: normalizeGlobalFoodText(query),
            normalizedStoreName: store != null
                ? normalizeGlobalFoodText(store)
                : null,
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
  required String? brand,
  required String? weight,
  required int limit,
}) async {
  try {
    final results = await repository.search(
      query: query,
      limit: limit,
      store: store,
      brand: brand,
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
