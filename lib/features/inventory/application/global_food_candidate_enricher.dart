part of 'global_food_item_matcher.dart';

class _GlobalFoodCandidateEnricher {
  const _GlobalFoodCandidateEnricher({
    InventoryItemRepository? inventoryRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
  }) : _inventoryRepository = inventoryRepository,
       _calorieProductCacheRepository = calorieProductCacheRepository;

  final InventoryItemRepository? _inventoryRepository;
  final CalorieProductCacheRepositoryContract? _calorieProductCacheRepository;

  Future<List<InventoryItem>> loadInventoryItems() async {
    return _inventoryRepository?.readAll() ?? const <InventoryItem>[];
  }

  Future<Map<String, GlobalFoodItem>> enrichProducts({
    required Iterable<GlobalFoodItem> products,
    required List<InventoryItem> inventoryItems,
  }) async {
    final uniqueProducts = {
      for (final product in products) product.id: product,
    }.values.toList(growable: false);
    if (uniqueProducts.isEmpty) {
      return const <String, GlobalFoodItem>{};
    }

    final inventoryEnriched = _applyInventorySamples(
      products: uniqueProducts,
      inventoryItems: inventoryItems,
    );
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

  Map<String, GlobalFoodItem> _applyInventorySamples({
    required List<GlobalFoodItem> products,
    required List<InventoryItem> inventoryItems,
  }) {
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

    return {
      for (final product in products)
        product.id: _applyInventorySample(
          product: product,
          sample:
              samplesByGlobalId[product.id] ??
              samplesByFingerprint[product.resolvedFoodFingerprint],
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
