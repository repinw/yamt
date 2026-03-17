import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'global_food_item_matcher.g.dart';

@riverpod
GlobalFoodItemMatcher globalFoodItemMatcher(Ref ref) {
  final repository = ref.watch(globalFoodItemRepositoryProvider);
  final inventoryRepository = ref.watch(inventoryItemRepositoryProvider);
  return GlobalFoodItemMatcher(
    repository: repository,
    inventoryRepository: inventoryRepository,
    calorieProductCacheRepository: ref.watch(
      calorieProductCacheRepositoryProvider,
    ),
  );
}

class GlobalFoodItemMatcher {
  const GlobalFoodItemMatcher({
    required GlobalFoodItemRepository repository,
    InventoryItemRepository? inventoryRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
  }) : _repository = repository,
       _inventoryRepository = inventoryRepository,
       _calorieProductCacheRepository = calorieProductCacheRepository;

  final GlobalFoodItemRepository _repository;
  final InventoryItemRepository? _inventoryRepository;
  final CalorieProductCacheRepositoryContract? _calorieProductCacheRepository;

  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    final results = await Future.wait([
      _repository.readAll(),
      _inventoryRepository?.readAll() ??
          Future<List<InventoryItem>>.value(const <InventoryItem>[]),
    ]);
    final products = results[0] as List<GlobalFoodItem>;
    final inventoryItems = results[1] as List<InventoryItem>;
    final enrichedProducts = await _enrichProducts(
      products: products,
      inventoryItems: inventoryItems,
    );
    final matches =
        products
            .map(
              (product) => _scoreCandidate(item, enrichedProducts[product.id]!),
            )
            .whereType<GlobalFoodMatchCandidate>()
            .toList(growable: false)
          ..sort((left, right) => right.score.compareTo(left.score));
    return matches.take(5).toList(growable: false);
  }

  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first.item.id;
  }

  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return false;
    }
    final best = candidates.first;
    if (best.reason == GlobalFoodMatchReason.fingerprintExact) {
      return false;
    }
    return candidates.length > 1 || best.score < 75;
  }

  GlobalFoodMatchCandidate? _scoreCandidate(
    InventoryItem item,
    GlobalFoodItem product,
  ) {
    if (product.status == GlobalFoodItemStatus.merged) {
      return null;
    }

    var score = 0.0;
    var reason = GlobalFoodMatchReason.nameTokenMatch;
    final itemFingerprint = item.resolvedFoodFingerprint;
    if (product.resolvedFoodFingerprint == itemFingerprint) {
      score += 100;
      reason = GlobalFoodMatchReason.fingerprintExact;
    }

    final itemName = normalizeGlobalFoodText(item.name);
    if (product.normalizedName == itemName && itemName.isNotEmpty) {
      score += 45;
    }

    final itemBrand = normalizeGlobalFoodText(item.brand ?? '');
    final productBrand = product.normalizedBrand ?? '';
    if (itemBrand.isNotEmpty && productBrand == itemBrand) {
      score += 25;
    }

    final itemCategory = normalizeGlobalFoodText(item.category ?? '');
    final productCategory = normalizeGlobalFoodText(product.category ?? '');
    if (itemCategory.isNotEmpty && productCategory == itemCategory) {
      score += 8;
    }

    final itemTokens = buildGlobalFoodSearchTokens(
      name: item.name,
      brand: item.brand,
      category: item.category,
    ).toSet();
    final overlap = product.searchTokens.where(itemTokens.contains).length;
    if (overlap > 0) {
      score += overlap * 6;
    }

    if (score < 12) {
      return null;
    }
    if (reason != GlobalFoodMatchReason.fingerprintExact &&
        product.normalizedName == itemName &&
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
