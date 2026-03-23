import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'global_food_item_matcher.g.dart';
part 'global_food_candidate_enricher.dart';
part 'global_food_local_candidate_matcher.dart';
part 'off_product_candidate_source.dart';

const int _globalFoodCandidateQueryLimit = 20;

@Riverpod(keepAlive: true)
GlobalFoodItemMatcher globalFoodItemMatcher(Ref ref) {
  final repository = ref.watch(globalFoodItemRepositoryProvider);
  final inventoryRepository = ref.watch(inventoryItemRepositoryProvider);
  return GlobalFoodItemMatcher(
    repository: repository,
    inventoryRepository: inventoryRepository,
    calorieProductCacheRepository: ref.watch(
      calorieProductCacheRepositoryProvider,
    ),
    offProductSearchRepository: ref.watch(offProductSearchRepositoryProvider),
  );
}

class GlobalFoodItemMatcher {
  GlobalFoodItemMatcher({
    required GlobalFoodItemRepository repository,
    InventoryItemRepository? inventoryRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
    OffProductSearchRepository? offProductSearchRepository,
  }) : _repository = repository,
       _candidateEnricher = _GlobalFoodCandidateEnricher(
         inventoryRepository: inventoryRepository,
         calorieProductCacheRepository: calorieProductCacheRepository,
       ),
       _localCandidateMatcher = const _GlobalFoodLocalCandidateMatcher(),
       _externalCandidateSource = _OffProductCandidateSource(
         repository: offProductSearchRepository,
       );

  final GlobalFoodItemRepository _repository;
  final _GlobalFoodCandidateEnricher _candidateEnricher;
  final _GlobalFoodLocalCandidateMatcher _localCandidateMatcher;
  final _OffProductCandidateSource _externalCandidateSource;

  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    final matchesByItemId = await findCandidatesByItemId(<InventoryItem>[item]);
    return matchesByItemId[item.id] ?? const <GlobalFoodMatchCandidate>[];
  }

  Future<Map<String, List<GlobalFoodMatchCandidate>>> findCandidatesByItemId(
    Iterable<InventoryItem> items,
  ) async {
    final preparedSearches = [
      for (final item in items)
        _PreparedCandidateSearch(
          item: item,
          localInput: _localCandidateMatcher.buildLocalMatchInput(item),
        ),
    ];
    if (preparedSearches.isEmpty) {
      return const <String, List<GlobalFoodMatchCandidate>>{};
    }

    final searchableItems = preparedSearches
        .where((search) => search.query != null)
        .toList(growable: false);
    if (searchableItems.isEmpty) {
      return {
        for (final search in preparedSearches)
          search.item.id: const <GlobalFoodMatchCandidate>[],
      };
    }

    final localProductsByItemId = await _waitForMappedFutures({
      for (final search in searchableItems)
        search.item.id: _searchLocalProducts(search.query!),
    });
    final externalResultsByItemId = await _waitForMappedFutures({
      for (final search in searchableItems)
        search.item.id: _externalCandidateSource.search(search.item),
    });
    final enrichedProducts = await _buildEnrichedProducts(
      localProductsByItemId: localProductsByItemId,
      externalResultsByItemId: externalResultsByItemId,
    );

    return {
      for (final search in preparedSearches)
        search.item.id: _buildMatchesForSearch(
          search: search,
          localProducts:
              localProductsByItemId[search.item.id] ?? const <GlobalFoodItem>[],
          externalResults:
              externalResultsByItemId[search.item.id] ??
              const <OffProductSearchResult>[],
          enrichedProducts: enrichedProducts,
        ),
    };
  }

  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    return _localCandidateMatcher.defaultSelectionFor(candidates);
  }

  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    return _localCandidateMatcher.defaultSelectionNeedsReviewFor(candidates);
  }

  Future<List<GlobalFoodItem>> _searchLocalProducts(
    _GlobalFoodMatcherQuery query,
  ) {
    return _repository.searchCandidates(
      normalizedName: query.normalizedName,
      barcode: query.barcode,
      foodFingerprint: query.foodFingerprint,
      searchTokens: query.searchTokens,
      limit: _globalFoodCandidateQueryLimit,
    );
  }

  Future<Map<String, GlobalFoodItem>> _buildEnrichedProducts({
    required Map<String, List<GlobalFoodItem>> localProductsByItemId,
    required Map<String, List<OffProductSearchResult>> externalResultsByItemId,
  }) async {
    final productsById = <String, GlobalFoodItem>{};
    for (final products in localProductsByItemId.values) {
      for (final product in products) {
        productsById[product.id] = product;
      }
    }
    for (final results in externalResultsByItemId.values) {
      for (final result in results) {
        final product = _externalCandidateSource.productFrom(result);
        productsById[product.id] = product;
      }
    }
    if (productsById.isEmpty) {
      return const <String, GlobalFoodItem>{};
    }

    final inventoryItems = await _candidateEnricher.loadInventoryItems();
    return _candidateEnricher.enrichProducts(
      products: productsById.values,
      inventoryItems: inventoryItems,
    );
  }

  List<GlobalFoodMatchCandidate> _buildMatchesForSearch({
    required _PreparedCandidateSearch search,
    required List<GlobalFoodItem> localProducts,
    required List<OffProductSearchResult> externalResults,
    required Map<String, GlobalFoodItem> enrichedProducts,
  }) {
    if (search.query == null) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final localMatches = _dedupeCandidates(
      _localCandidateMatcher.scoreCandidates(
        search.localInput,
        localProducts.map((product) => enrichedProducts[product.id] ?? product),
      ),
    )..sort((left, right) => right.score.compareTo(left.score));
    final externalMatches = _dedupeCandidates(
      _buildExternalMatches(
        externalResults: externalResults,
        enrichedProducts: enrichedProducts,
      ),
    )..sort((left, right) => right.score.compareTo(left.score));
    return _mergeLocalAndExternalCandidates(
      localMatches: localMatches,
      externalMatches: externalMatches,
    ).take(5).toList(growable: false);
  }

  List<GlobalFoodMatchCandidate> _buildExternalMatches({
    required List<OffProductSearchResult> externalResults,
    required Map<String, GlobalFoodItem> enrichedProducts,
  }) {
    return externalResults
        .map((result) {
          final product =
              enrichedProducts[_externalCandidateSource.productIdFor(result)];
          if (product == null) {
            return null;
          }
          return GlobalFoodMatchCandidate(
            item: product,
            score: _scoreExternalCandidate(result.score),
            reason: GlobalFoodMatchReason.externalSearch,
            requiresPersistence: true,
          );
        })
        .whereType<GlobalFoodMatchCandidate>()
        .toList(growable: false);
  }

  Future<Map<String, T>> _waitForMappedFutures<T>(
    Map<String, Future<T>> futuresByKey,
  ) async {
    final entries = await Future.wait(
      futuresByKey.entries.map((entry) async {
        return MapEntry<String, T>(entry.key, await entry.value);
      }),
    );
    return Map<String, T>.fromEntries(entries);
  }

  double _scoreExternalCandidate(double rawScore) {
    return (60 + (rawScore / 2)).clamp(60, 89).toDouble();
  }

  List<GlobalFoodMatchCandidate> _dedupeCandidates(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    final bestByKey = <String, GlobalFoodMatchCandidate>{};
    for (final candidate in candidates) {
      final key = _candidateKey(candidate);
      final existing = bestByKey[key];
      final shouldReplace =
          existing == null ||
          candidate.score > existing.score ||
          (candidate.score == existing.score &&
              !candidate.requiresPersistence &&
              existing.requiresPersistence);
      if (shouldReplace) {
        bestByKey[key] = candidate;
      }
    }
    return bestByKey.values.toList(growable: false);
  }

  List<GlobalFoodMatchCandidate> _mergeLocalAndExternalCandidates({
    required List<GlobalFoodMatchCandidate> localMatches,
    required List<GlobalFoodMatchCandidate> externalMatches,
  }) {
    final merged = <GlobalFoodMatchCandidate>[];
    final seenKeys = <String>{};

    for (final candidate in localMatches) {
      final key = _candidateKey(candidate);
      if (seenKeys.add(key)) {
        merged.add(candidate);
      }
    }

    for (final candidate in externalMatches) {
      final key = _candidateKey(candidate);
      if (seenKeys.add(key)) {
        merged.add(candidate);
      }
    }

    return merged;
  }

  String _candidateKey(GlobalFoodMatchCandidate candidate) {
    final barcode = candidate.item.normalizedBarcode;
    if (barcode != null && barcode.isNotEmpty) {
      return 'barcode:$barcode';
    }

    return 'name:${candidate.item.normalizedName}'
        '|brand:${candidate.item.normalizedBrand ?? ''}';
  }
}

class _PreparedCandidateSearch {
  _PreparedCandidateSearch({required this.item, required this.localInput})
    : query = _GlobalFoodLocalCandidateMatcher.buildQuery(localInput);

  final InventoryItem item;
  final _LocalMatchInput localInput;
  final _GlobalFoodMatcherQuery? query;
}
