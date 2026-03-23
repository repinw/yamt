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
}
