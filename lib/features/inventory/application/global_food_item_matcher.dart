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

const int _globalFoodCandidateQueryLimit = 20;
const int _globalFoodQueryTokenLimit = 10;

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
  const GlobalFoodItemMatcher({
    required GlobalFoodItemRepository repository,
    InventoryItemRepository? inventoryRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
    OffProductSearchRepository? offProductSearchRepository,
  }) : _repository = repository,
       _inventoryRepository = inventoryRepository,
       _calorieProductCacheRepository = calorieProductCacheRepository,
       _offProductSearchRepository = offProductSearchRepository;

  final GlobalFoodItemRepository _repository;
  final InventoryItemRepository? _inventoryRepository;
  final CalorieProductCacheRepositoryContract? _calorieProductCacheRepository;
  final OffProductSearchRepository? _offProductSearchRepository;

  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    final localMatchInput = _buildLocalMatchInput(item);
    final query = _buildQuery(item, localMatchInput);
    if (query == null) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final results = await Future.wait<Object>(<Future<Object>>[
      _repository.searchCandidates(
        normalizedName: query.normalizedName,
        barcode: query.barcode,
        foodFingerprint: query.foodFingerprint,
        searchTokens: query.searchTokens,
        limit: _globalFoodCandidateQueryLimit,
      ),
      _searchExternalCandidates(item),
    ]);
    final products = results[0] as List<GlobalFoodItem>;
    final externalResults = results[1] as List<OffProductSearchResult>;
    if (products.isEmpty && externalResults.isEmpty) {
      return const <GlobalFoodMatchCandidate>[];
    }

    final externalProducts = externalResults
        .map(_externalProductFromSearchResult)
        .toList(growable: false);
    final allProducts = <GlobalFoodItem>[...products, ...externalProducts];

    final inventoryItems =
        await _inventoryRepository?.readAll() ?? const <InventoryItem>[];
    final enrichedProducts = await _enrichProducts(
      products: allProducts,
      inventoryItems: inventoryItems,
    );
    final localMatches =
        products
            .map(
              (product) => _scoreCandidate(
                localMatchInput,
                enrichedProducts[product.id]!,
              ),
            )
            .whereType<GlobalFoodMatchCandidate>()
            .toList(growable: false)
          ..sort((left, right) => right.score.compareTo(left.score));
    final externalMatches =
        externalResults
            .map((result) {
              final product = enrichedProducts[_externalProductIdFor(result)];
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
            .toList(growable: false)
          ..sort((left, right) => right.score.compareTo(left.score));
    final dedupedLocalMatches = _dedupeCandidates(localMatches)
      ..sort((left, right) => right.score.compareTo(left.score));
    final dedupedExternalMatches = _dedupeCandidates(externalMatches)
      ..sort((left, right) => right.score.compareTo(left.score));
    final matches = _mergeLocalAndExternalCandidates(
      localMatches: dedupedLocalMatches,
      externalMatches: dedupedExternalMatches,
    );
    return matches.take(5).toList(growable: false);
  }

  _GlobalFoodMatcherQuery? _buildQuery(
    InventoryItem item,
    _LocalMatchInput localMatchInput,
  ) {
    final normalizedName = localMatchInput.normalizedName;
    final searchTokens = localMatchInput.nameTokens;
    final barcode = item.normalizedBarcode;
    final foodFingerprint = localMatchInput.foodFingerprint;

    final hasQuery =
        normalizedName.isNotEmpty ||
        searchTokens.isNotEmpty ||
        barcode != null ||
        foodFingerprint != null;
    if (!hasQuery) {
      return null;
    }

    return _GlobalFoodMatcherQuery(
      normalizedName: normalizedName.isEmpty ? null : normalizedName,
      barcode: barcode,
      foodFingerprint: foodFingerprint,
      searchTokens: searchTokens,
    );
  }

  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    final best = candidates.first;
    return switch (best.reason) {
      GlobalFoodMatchReason.fingerprintExact => best.item.id,
      GlobalFoodMatchReason.nameBrandStrong =>
        _hasConfidentLead(candidates) ? best.item.id : null,
      GlobalFoodMatchReason.nameExact =>
        candidates.length == 1 ? best.item.id : null,
      GlobalFoodMatchReason.nameTokenMatch ||
      GlobalFoodMatchReason.externalSearch => null,
    };
  }

  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return false;
    }
    return defaultSelectionFor(candidates) == null;
  }

  GlobalFoodMatchCandidate? _scoreCandidate(
    _LocalMatchInput item,
    GlobalFoodItem product,
  ) {
    if (product.status == GlobalFoodItemStatus.merged) {
      return null;
    }

    var score = 0.0;
    var reason = GlobalFoodMatchReason.nameTokenMatch;
    final itemFingerprint = item.foodFingerprint;
    if (product.resolvedFoodFingerprint == itemFingerprint) {
      score += 100;
      reason = GlobalFoodMatchReason.fingerprintExact;
    }

    final itemName = item.normalizedName;
    final isExactNameMatch =
        product.normalizedName == itemName && itemName.isNotEmpty;
    if (isExactNameMatch) {
      score += 45;
      if (reason != GlobalFoodMatchReason.fingerprintExact) {
        reason = GlobalFoodMatchReason.nameExact;
      }
    }

    final itemBrand = item.normalizedBrand;
    final productBrand = product.normalizedBrand ?? '';
    if (itemBrand.isNotEmpty && productBrand == itemBrand) {
      score += 25;
    }

    final itemCategory = item.normalizedCategory;
    final productCategory = normalizeGlobalFoodText(product.category ?? '');
    if (itemCategory.isNotEmpty && productCategory == itemCategory) {
      score += 8;
    }

    final overlap = product.searchTokens
        .where(item.nameTokenSet.contains)
        .length;
    if (overlap > 0) {
      score += overlap * 6;
    }

    if (score < 12) {
      return null;
    }
    if (reason != GlobalFoodMatchReason.fingerprintExact &&
        isExactNameMatch &&
        itemBrand.isNotEmpty &&
        productBrand == itemBrand) {
      reason = GlobalFoodMatchReason.nameBrandStrong;
    }

    return GlobalFoodMatchCandidate(
      item: product,
      score: score,
      reason: reason,
    );
  }

  _LocalMatchInput _buildLocalMatchInput(InventoryItem item) {
    final normalizedName = normalizeGlobalFoodText(item.name);
    final normalizedBrand = normalizeGlobalFoodText(item.brand ?? '');
    final normalizedCategory = normalizeGlobalFoodText(item.category ?? '');
    final foodFingerprint = _queryFoodFingerprintFor(item);
    final tokens = _queryNameTokensFor(item.name);
    return _LocalMatchInput(
      normalizedName: normalizedName,
      normalizedBrand: normalizedBrand,
      normalizedCategory: normalizedCategory,
      foodFingerprint: foodFingerprint,
      nameTokens: tokens,
      nameTokenSet: tokens.toSet(),
    );
  }

  List<String> _queryNameTokensFor(String name) {
    final tokens = buildGlobalFoodSearchTokens(
      name: name,
    ).toSet().toList(growable: false);
    tokens.sort((left, right) {
      final lengthCompare = right.length.compareTo(left.length);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      return left.compareTo(right);
    });
    return tokens.take(_globalFoodQueryTokenLimit).toList(growable: false);
  }

  bool _hasConfidentLead(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.length < 2) {
      return true;
    }
    return candidates.first.score - candidates[1].score >= 8;
  }

  String? _queryFoodFingerprintFor(InventoryItem item) {
    final fingerprint = item.resolvedFoodFingerprint.trim();
    if (fingerprint.isEmpty || fingerprint == 'unknown_food') {
      return null;
    }
    return fingerprint;
  }

  Future<Map<String, GlobalFoodItem>> _enrichProducts({
    required List<GlobalFoodItem> products,
    required List<InventoryItem> inventoryItems,
  }) async {
    final samplesByGlobalId = <String, InventoryItem>{};
    final samplesByFingerprint = <String, InventoryItem>{};

    for (final item in inventoryItems) {
      if (!_hasCandidateEnrichment(item)) {
        continue;
      }

      if (!samplesByGlobalId.containsKey(item.globalFoodItemId)) {
        samplesByGlobalId[item.globalFoodItemId] = item;
      }

      final fingerprint = item.resolvedFoodFingerprint;
      if (!samplesByFingerprint.containsKey(fingerprint)) {
        samplesByFingerprint[fingerprint] = item;
      }
    }

    final inventoryEnriched = {
      for (final product in products)
        product.id: _applyInventorySample(
          product: product,
          sample:
              samplesByGlobalId[product.id] ??
              samplesByFingerprint[product.resolvedFoodFingerprint],
        ),
    };

    final barcodes = inventoryEnriched.values
        .map((product) => product.normalizedBarcode)
        .whereType<String>()
        .where((barcode) => barcode.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (barcodes.isEmpty || _calorieProductCacheRepository == null) {
      return inventoryEnriched;
    }

    final calorieProfiles = await Future.wait(
      barcodes.map(_readCalorieProfileForBarcode),
    );
    final profileByBarcode = <String, CalorieProductProfile>{};
    for (final entry in calorieProfiles) {
      if (entry == null) {
        continue;
      }
      profileByBarcode[entry.barcode] = entry;
    }

    return {
      for (final product in inventoryEnriched.values)
        product.id: _applyCalorieProfile(
          product: product,
          profile: product.normalizedBarcode == null
              ? null
              : profileByBarcode[product.normalizedBarcode!],
        ),
    };
  }

  Future<List<OffProductSearchResult>> _searchExternalCandidates(
    InventoryItem item,
  ) async {
    final repository = _offProductSearchRepository;
    if (repository == null) {
      return const <OffProductSearchResult>[];
    }

    final query = item.name.trim();
    if (query.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final rawBrand = item.brand?.trim();
    final normalizedBrandStore = _normalizeSupportedExternalStore(rawBrand);
    final store = _resolveExternalStore(
      storeName: item.storeName,
      brandStore: normalizedBrandStore,
    );
    final isNettoSearch = store == 'Netto';
    final effectiveBrand = isNettoSearch && normalizedBrandStore == store
        ? null
        : rawBrand;
    return repository.search(
      query: query,
      store: store,
      brand: isNettoSearch ? effectiveBrand : null,
      weight: isNettoSearch ? item.weight?.trim() : null,
      limit: _globalFoodCandidateQueryLimit,
    );
  }

  String? _resolveExternalStore({
    required String storeName,
    required String? brandStore,
  }) {
    final normalizedStore = _normalizeSupportedExternalStore(storeName);
    if (normalizedStore != null) {
      return normalizedStore;
    }
    return brandStore;
  }

  String? _normalizeSupportedExternalStore(String? rawValue) {
    final normalized = normalizeStoreName(rawValue);
    return switch (normalized) {
      'Aldi' => 'Aldi',
      'Netto' => 'Netto',
      _ => null,
    };
  }

  GlobalFoodItem _externalProductFromSearchResult(
    OffProductSearchResult result,
  ) {
    return GlobalFoodItem.create(
      id: _externalProductIdFor(result),
      name: result.name,
      now: DateTime.now(),
      brand: result.brand,
      barcode: result.code,
      imageUrl: result.imageUrl,
      packageWeight: result.packageWeight,
      nutrition: result.nutrition,
    );
  }

  String _externalProductIdFor(OffProductSearchResult result) {
    final code = result.code.trim();
    if (code.isNotEmpty) {
      return 'off-$code';
    }

    final normalizedName = normalizeGlobalFoodText(result.name);
    final normalizedBrand = normalizeGlobalFoodText(result.brand ?? '');
    final composite = [
      normalizedName,
      normalizedBrand,
    ].where((value) => value.isNotEmpty).join('-');
    return 'off-${composite.isEmpty ? 'product' : composite}';
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

  bool _hasCandidateEnrichment(InventoryItem item) {
    return item.normalizedBarcode != null ||
        item.imageUrl != null ||
        item.nutrition != null;
  }

  GlobalFoodItem _applyInventorySample({
    required GlobalFoodItem product,
    required InventoryItem? sample,
  }) {
    if (sample == null) {
      return product;
    }

    return product.copyWith(
      barcode: product.normalizedBarcode ?? sample.normalizedBarcode,
      imageUrl: product.imageUrl ?? sample.imageUrl,
      nutrition: product.nutrition ?? sample.nutrition,
    );
  }

  Future<CalorieProductProfile?> _readCalorieProfileForBarcode(
    String barcode,
  ) async {
    final repository = _calorieProductCacheRepository;
    if (repository == null) {
      return null;
    }
    return await repository.readUserOverride(barcode) ??
        await repository.readGlobalProduct(barcode);
  }

  GlobalFoodItem _applyCalorieProfile({
    required GlobalFoodItem product,
    required CalorieProductProfile? profile,
  }) {
    if (profile == null) {
      return product;
    }

    return product.copyWith(
      imageUrl: product.imageUrl ?? profile.imageUrl,
      nutrition: product.nutrition ?? _nutritionFromProfile(profile),
    );
  }

  GlobalFoodNutrition _nutritionFromProfile(CalorieProductProfile profile) {
    final allZero =
        profile.per100Kcal == 0 &&
        profile.per100Protein == 0 &&
        profile.per100Carbs == 0 &&
        profile.per100Fat == 0;
    return GlobalFoodNutrition(
      qualityStatus: allZero
          ? GlobalFoodNutritionQualityStatus.unverified
          : GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
    );
  }
}

class _GlobalFoodMatcherQuery {
  const _GlobalFoodMatcherQuery({
    required this.normalizedName,
    required this.barcode,
    required this.foodFingerprint,
    required this.searchTokens,
  });

  final String? normalizedName;
  final String? barcode;
  final String? foodFingerprint;
  final List<String> searchTokens;
}

class _LocalMatchInput {
  const _LocalMatchInput({
    required this.normalizedName,
    required this.normalizedBrand,
    required this.normalizedCategory,
    required this.foodFingerprint,
    required this.nameTokens,
    required this.nameTokenSet,
  });

  final String normalizedName;
  final String normalizedBrand;
  final String normalizedCategory;
  final String? foodFingerprint;
  final List<String> nameTokens;
  final Set<String> nameTokenSet;
}
