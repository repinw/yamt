part of 'global_food_item_matcher.dart';

class _OffProductCandidateSource {
  const _OffProductCandidateSource({
    required OffProductSearchRepository? repository,
  }) : _repository = repository;

  final OffProductSearchRepository? _repository;

  Future<List<OffProductSearchResult>> search(InventoryItem item) async {
    final repository = _repository;
    if (repository == null) {
      return const <OffProductSearchResult>[];
    }

    final query = (item.ocrName ?? item.name).trim();
    if (query.isEmpty) {
      return const <OffProductSearchResult>[];
    }

    final rawBrand = item.brand?.trim();
    final normalizedStoreName = normalizeStoreName(item.storeName);
    final normalizedBrandName = normalizeStoreName(rawBrand);
    final normalizedBrandStore = _normalizeSupportedExternalStore(rawBrand);
    final store = _resolveExternalStore(
      normalizedStoreName: normalizedStoreName,
      brandStore: normalizedBrandStore,
    );
    final isNettoSearch = store == 'Netto';
    final isGeneralCollectionSearch =
        store == null || (store != 'Aldi' && store != 'Netto');
    final brandRepeatsStore =
        normalizedStoreName != null &&
        normalizedBrandName != null &&
        normalizedStoreName == normalizedBrandName;
    final effectiveBrand =
        brandRepeatsStore || (isNettoSearch && normalizedBrandStore == store)
        ? null
        : rawBrand;
    final effectiveWeight = item.weight?.trim();
    return repository.search(
      query: query,
      store: store,
      brand: isNettoSearch || isGeneralCollectionSearch ? effectiveBrand : null,
      weight: isNettoSearch || isGeneralCollectionSearch
          ? effectiveWeight
          : null,
      limit: _globalFoodReviewCandidateLimitPerSource,
    );
  }

  GlobalFoodItem productFrom(OffProductSearchResult result) {
    return GlobalFoodItem.create(
      id: productIdFor(result),
      name: result.name,
      now: DateTime.now(),
      brand: result.brand,
      barcode: result.code,
      imageUrl: result.imageUrl,
      packageWeight: result.packageWeight,
      nutrition: result.nutrition,
    );
  }

  String productIdFor(OffProductSearchResult result) {
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

  String? _resolveExternalStore({
    required String? normalizedStoreName,
    required String? brandStore,
  }) {
    final normalizedStore = _normalizeSupportedExternalStore(
      normalizedStoreName,
    );
    if (normalizedStore != null) {
      return normalizedStore;
    }
    if (_isGeneralFallbackStore(normalizedStoreName)) {
      return normalizedStoreName;
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

  bool _isGeneralFallbackStore(String? normalizedStoreName) {
    if (normalizedStoreName == null || normalizedStoreName.isEmpty) {
      return false;
    }
    return normalizedStoreName != 'Unknown';
  }
}
