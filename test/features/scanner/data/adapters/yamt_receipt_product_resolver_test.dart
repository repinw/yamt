import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

class _FakeMatcher extends GlobalFoodItemMatcher {
  List<GlobalFoodMatchCandidate> candidatesToReturn =
      const <GlobalFoodMatchCandidate>[];
  final List<InventoryItem> recordedItems = <InventoryItem>[];

  @override
  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    recordedItems.add(item);
    return candidatesToReturn;
  }

  @override
  Future<Map<String, List<GlobalFoodMatchCandidate>>> findCandidatesByItemId(
    Iterable<InventoryItem> items,
  ) async {
    recordedItems.addAll(items);
    return {for (final item in items) item.id: candidatesToReturn};
  }
}

class _FakeOffSearchRepo implements OffProductSearchRepository {
  List<OffProductSearchResult> searchResults = const <OffProductSearchResult>[];
  List<OffProductSearchResult> barcodeResults =
      const <OffProductSearchResult>[];
  String? recordedStore;
  String? recordedBrand;
  String? recordedWeight;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    recordedStore = store;
    recordedBrand = brand;
    recordedWeight = weight;
    return searchResults;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return barcodeResults;
  }
}

void main() {
  group('YamtReceiptProductResolver', () {
    late _FakeMatcher matcher;
    late _FakeOffSearchRepo searchRepo;
    late YamtReceiptProductResolver resolver;

    final testGlobalItem = GlobalFoodItem(
      id: 'g_123',
      name: 'Vollmilch 3.8%',
      normalizedName: 'vollmilch 3 8',
      brand: 'Ja!',
      barcode: '4311501234567',
      category: 'Milch',
      imageUrl: 'https://example.com/milch.png',
      packageWeight: '1L',
      foodFingerprint: 'vollmilch__ja',
      searchTokens: const ['vollmilch'],
      status: GlobalFoodItemStatus.active,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 64,
        per100Protein: 3.3,
        per100Carbs: 4.8,
        per100Fat: 3.8,
      ),
    );

    setUp(() {
      matcher = _FakeMatcher();
      searchRepo = _FakeOffSearchRepo();
      resolver = YamtReceiptProductResolver(
        matcher: matcher,
        searchRepository: searchRepo,
      );
    });

    test('resolveCandidates returns empty list on blank input', () async {
      final result = await resolver.resolveCandidates(rawLineText: '   ');
      expect(result, isEmpty);
      expect(matcher.recordedItems, isEmpty);
    });

    test('resolveCandidates maps candidates and nutrition cleanly', () async {
      matcher.candidatesToReturn = [
        GlobalFoodMatchCandidate(
          item: testGlobalItem,
          score: 0.95,
          reason: GlobalFoodMatchReason.receiptAliasExact,
          requiresPersistence: true,
        ),
      ];

      final result = await resolver.resolveCandidates(
        rawLineText: 'JA! VOLLMILCH 1L',
        storeName: 'REWE',
      );

      expect(result.length, 1);
      final candidate = result.first;
      expect(candidate.id, 'g_123');
      expect(candidate.name, 'Vollmilch 3.8%');
      expect(candidate.brand, 'Ja!');
      expect(candidate.confidence, 0.95);
      expect(candidate.source, CandidateSource.aliasExact);
      expect(candidate.requiresPersistence, isTrue);
      expect(candidate.nutritionPer100g?['kcal'], 64);
      expect(candidate.nutritionPer100g?['protein'], 3.3);
      expect(matcher.recordedItems.first.storeName, 'REWE');
    });

    test('resolveBatch resolves multiple line items', () async {
      matcher.candidatesToReturn = [
        GlobalFoodMatchCandidate(
          item: testGlobalItem,
          score: 0.88,
          reason: GlobalFoodMatchReason.nameExact,
        ),
      ];

      final batchResult = await resolver.resolveBatch(
        items: const [
          ReceiptLineItem(
            id: 'milk',
            rawName: 'JA! VOLLMILCH 1L',
            totalPrice: 1.49,
            rawBrand: 'Ja!',
            packageWeight: '1L',
          ),
          ReceiptLineItem(
            id: 'bananas',
            rawName: 'BANANEN BIO',
            totalPrice: 2.29,
          ),
        ],
        storeName: 'ALDI',
      );

      expect(batchResult.length, 2);
      expect(batchResult['milk']?.first.source, CandidateSource.history);
      expect(batchResult['bananas']?.first.id, 'g_123');
      final milkLookup = matcher.recordedItems.firstWhere(
        (item) => item.id == 'milk',
      );
      expect(milkLookup.storeName, 'ALDI');
      expect(milkLookup.brand, 'Ja!');
      expect(milkLookup.weight, '1L');
    });

    test(
      'resolveByBarcode handles empty and present barcode lookups',
      () async {
        final emptyResult = await resolver.resolveByBarcode('');
        expect(emptyResult, isNull);

        searchRepo.barcodeResults = [
          const OffProductSearchResult(
            code: '4008300001018',
            name: 'Bauernbrot 500g',
            score: 1,
            brand: 'Harry',
          ),
        ];

        final found = await resolver.resolveByBarcode('4008300001018');
        expect(found, isNotNull);
        expect(found!.name, 'Bauernbrot 500g');
        expect(found.brand, 'Harry');
        expect(found.source, CandidateSource.barcode);
        expect(found.requiresPersistence, isTrue);
      },
    );

    test('searchByName returns mapped search results', () async {
      final empty = await resolver.searchByName('  ');
      expect(empty, isEmpty);

      searchRepo.searchResults = [
        const OffProductSearchResult(
          code: '4000521005018',
          name: 'Haferflocken',
          score: 0.85,
          brand: 'Kölln',
        ),
      ];

      final results = await resolver.searchByName(
        'Haferflocken',
        storeName: 'Netto',
        brand: 'SG GGN',
        weight: '200g',
      );
      expect(results.length, 1);
      expect(results.first.name, 'Haferflocken');
      expect(results.first.requiresPersistence, isTrue);
      expect(results.first.brand, 'Kölln');
      expect(results.first.source, CandidateSource.manualSearch);
      expect(searchRepo.recordedStore, 'Netto');
      expect(searchRepo.recordedBrand, 'SG GGN');
      expect(searchRepo.recordedWeight, '200g');
    });
  });
}
