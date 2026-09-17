import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/adapters/'
    'yamt_nutrition_converter.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

/// Yamt adapter implementing [ReceiptProductResolver].
///
/// Bridges the scanner's decoupled resolver interface to Yamt's
/// [GlobalFoodItemMatcher] and [OffProductSearchRepository].
class YamtReceiptProductResolver implements ReceiptProductResolver {
  /// Creates a [YamtReceiptProductResolver].
  const new({
    required this._matcher,
    required this._searchRepository,
  });

  final GlobalFoodItemMatcher _matcher;
  final OffProductSearchRepository _searchRepository;

  @override
  Future<List<ProductCandidate>> resolveCandidates({
    required String rawLineText,
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    final trimmed = rawLineText.trim();
    if (trimmed.isEmpty) return const <ProductCandidate>[];

    final item = _buildTempItem(
      id: trimmed,
      name: trimmed,
      storeName: storeName,
      brand: brand,
      weight: weight,
    );
    final candidates = await _matcher.findCandidates(item);
    return candidates.map(_mapCandidate).toList(growable: false);
  }

  @override
  Future<Map<String, List<ProductCandidate>>> resolveBatch({
    required List<ReceiptLineItem> items,
    String? storeName,
  }) async {
    if (items.isEmpty) return const <String, List<ProductCandidate>>{};

    final itemsById = <String, InventoryItem>{};
    for (final item in items) {
      itemsById[item.id] = _buildTempItem(
        id: item.id,
        name: item.rawName,
        storeName: storeName,
        brand: item.rawBrand,
        weight: item.packageWeight,
      );
    }

    final matchMap = await _matcher.findCandidatesByItemId(itemsById.values);
    final result = <String, List<ProductCandidate>>{};

    for (final item in items) {
      final matches = matchMap[item.id] ?? const <GlobalFoodMatchCandidate>[];
      result[item.id] = matches.map(_mapCandidate).toList(growable: false);
    }

    return result;
  }

  @override
  Future<ProductCandidate?> resolveByBarcode(String barcode) async {
    final candidates = await resolveCandidatesByBarcode(barcode);
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Future<List<ProductCandidate>> resolveCandidatesByBarcode(
    String barcode,
  ) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return const <ProductCandidate>[];

    final results = await _searchRepository.lookupCandidatesByBarcode(
      barcode: trimmed,
    );
    if (results.isEmpty) return const <ProductCandidate>[];

    return results
        .map((r) => _mapSearchResult(r, source: CandidateSource.barcode))
        .toList()
      ..sort((a, b) {
        if (a.hasNutrition && !b.hasNutrition) return -1;
        if (!a.hasNutrition && b.hasNutrition) return 1;
        return b.confidence.compareTo(a.confidence);
      });
  }

  @override
  Future<List<ProductCandidate>> searchByName(
    String query, {
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <ProductCandidate>[];

    final results = await _searchRepository.search(
      query: trimmed,
      store: storeName,
      brand: brand,
      weight: weight,
    );
    return results
        .map((r) => _mapSearchResult(r, source: CandidateSource.manualSearch))
        .toList(growable: false);
  }

  InventoryItem _buildTempItem({
    required String id,
    required String name,
    String? storeName,
    String? brand,
    String? weight,
  }) {
    return InventoryItem.create(
      id: id,
      name: name,
      storeName: storeName ?? '',
      brand: brand,
      weight: weight,
      entryDate: DateTime.now(),
      quantity: 1,
      ocrName: name,
    );
  }

  ProductCandidate _mapCandidate(GlobalFoodMatchCandidate candidate) {
    final item = candidate.item;
    return ProductCandidate(
      id: item.id,
      name: item.name,
      brand: item.brand,
      category: item.category,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      packageSize: item.packageWeight,
      confidence: candidate.score,
      source: _mapReason(candidate.reason),
      requiresPersistence: candidate.requiresPersistence,
      nutritionPer100g: YamtNutritionConverter.toNutritionMap(item.nutrition),
    );
  }

  ProductCandidate _mapSearchResult(
    OffProductSearchResult result, {
    CandidateSource source = CandidateSource.catalogFuzzy,
  }) {
    return ProductCandidate(
      id: result.globalFoodItemId ?? result.code,
      name: result.name,
      brand: result.brand,
      barcode: result.code,
      imageUrl: result.imageUrl,
      packageSize: result.packageWeight,
      confidence: result.score,
      source: source,
      requiresPersistence: true,
      nutritionPer100g: YamtNutritionConverter.toNutritionMap(result.nutrition),
    );
  }

  CandidateSource _mapReason(GlobalFoodMatchReason reason) {
    return switch (reason) {
      GlobalFoodMatchReason.receiptAliasExact => CandidateSource.aliasExact,
      GlobalFoodMatchReason.externalSearch => CandidateSource.catalogFuzzy,
      GlobalFoodMatchReason.fingerprintExact ||
      GlobalFoodMatchReason.nameExact ||
      GlobalFoodMatchReason.nameBrandStrong ||
      GlobalFoodMatchReason.nameTokenMatch => CandidateSource.history,
    };
  }
}
