import 'dart:async' show TimeoutException;
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
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
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

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
    currentUserId: ref.watch(authStateChangesProvider).asData?.value?.uid,
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
    this._currentUserId,
  });

  final OffProductSearchRepository _offRepository;
  final GlobalFoodItemRepository? _globalFoodItemRepository;
  final GlobalBarcodeCandidateRepository? _barcodeCandidateRepository;
  final ManualProductRecentItemsService? _recentItemsService;

  /// The signed-in user, whose own catalog foods keep their rank.
  final String? _currentUserId;

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
      currentUserId: _currentUserId,
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
    final learnedRead = _readBarcodeSource(
      source: 'Learned barcode candidate',
      barcode: barcode,
      read: () async =>
          await _barcodeCandidateRepository?.readCandidates(barcode: barcode) ??
          const <GlobalBarcodeCandidate>[],
    );
    final offRead = _readBarcodeSource(
      source: 'OFF barcode candidate',
      barcode: barcode,
      read: () => _offRepository.lookupCandidatesByBarcode(barcode: barcode),
    );
    final learned = await learnedRead;
    final off = await offRead;
    final candidates = mergeInventoryBarcodeCandidates(
      learnedCandidates: learned.candidates,
      offCandidates: off.candidates,
    );
    // Nothing found only means "unknown barcode" when every source answered.
    if (candidates.isEmpty && (learned.isUnreachable || off.isUnreachable)) {
      throw const BarcodeLookupOfflineException();
    }
    return candidates;
  }

  @override
  Future<List<InventoryItem>> readRecentItems() async {
    final service = _recentItemsService;
    if (service == null) {
      return const <InventoryItem>[];
    }
    return await service.readRecentItems();
  }

  /// Reads one barcode source. A failed source counts as empty, so the other
  /// source can still show its candidates. `isUnreachable` marks an empty
  /// result that proves nothing, because the source could not be reached.
  Future<({List<T> candidates, bool isUnreachable})> _readBarcodeSource<T>({
    required String source,
    required String barcode,
    required Future<List<T>> Function() read,
  }) async {
    try {
      return (candidates: await read(), isUnreachable: false);
    } on Object catch (error, stackTrace) {
      log(
        '$source lookup failed for $barcode.',
        name: _productSearchHubSearchLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return (candidates: <T>[], isUnreachable: _isConnectionFailure(error));
    }
  }
}

/// Whether [error] means that a source could not be reached, for example
/// without a connection. The HTTP client reports socket errors as
/// [http.ClientException], Firestore as `unavailable` or `deadline-exceeded`.
bool _isConnectionFailure(Object error) {
  return switch (error) {
    http.ClientException() || TimeoutException() => true,
    FirebaseException(code: 'unavailable' || 'deadline-exceeded') => true,
    _ => false,
  };
}

/// Runs product search and applies hub dedupe rules across Firebase and OFF.
///
/// Catalog results come first, then OFF results, and last the catalog foods
/// without barcode that [currentUserId] did not create, such as another
/// user's AI meal (#655).
Future<ProductSearchHubSearchLookupResult> lookupProductSearchHubProducts({
  required OffProductSearchRepository repository,
  required String query,
  required int limit,
  GlobalFoodItemRepository? globalFoodItemRepository,
  String? currentUserId,
  String? store,
  String? brand,
  String? weight,
}) async {
  try {
    final normalized = normalizeBarcode(query);
    final isBarcode = normalized.isNotEmpty && isSupportedBarcode(normalized);

    final catalogItemsFuture = _lookupGlobalFoodItems(
      repository: globalFoodItemRepository,
      query: query,
      barcode: isBarcode ? normalized : null,
      store: store,
      limit: limit,
    );
    final offResultsFuture = _lookupOffProducts(
      repository: repository,
      query: query,
      barcode: isBarcode ? normalized : null,
      store: store,
      brand: brand,
      weight: weight,
      limit: limit,
    );
    final catalogItems = await catalogItemsFuture;
    final offResults = await offResultsFuture;

    final combined = <OffProductSearchResult>[
      for (final item in catalogItems)
        if (!_isOtherUsersFood(item, currentUserId))
          OffProductSearchResult.fromGlobalFoodItem(item),
      ...offResults,
      for (final item in catalogItems)
        if (_isOtherUsersFood(item, currentUserId))
          OffProductSearchResult.fromGlobalFoodItem(item),
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

/// Whether [item] is a food without barcode, such as an AI estimate of a
/// meal, that [currentUserId] did not create. Such a food belongs to its
/// author, not to a package other users can buy. An item from before the
/// catalog recorded its author counts as another user's.
bool _isOtherUsersFood(GlobalFoodItem item, String? currentUserId) {
  return item.normalizedBarcode == null &&
      (currentUserId == null || item.createdByUid != currentUserId);
}

Future<List<GlobalFoodItem>> _lookupGlobalFoodItems({
  required GlobalFoodItemRepository? repository,
  required String query,
  required String? barcode,
  required String? store,
  required int limit,
}) async {
  if (repository == null) {
    return const <GlobalFoodItem>[];
  }
  try {
    return barcode != null
        ? await repository.searchCandidates(barcode: barcode, limit: limit)
        : await repository.searchCandidates(
            normalizedName: normalizeGlobalFoodText(query),
            normalizedStoreName: store != null
                ? normalizeGlobalFoodText(store)
                : null,
            searchTokens: buildGlobalFoodSearchTokens(name: query),
            limit: limit,
          );
  } on Object catch (error, stackTrace) {
    log(
      'Global food item search failed for query "$query".',
      name: _productSearchHubSearchLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <GlobalFoodItem>[];
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
