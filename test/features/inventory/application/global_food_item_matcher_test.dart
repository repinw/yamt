import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _SearchCall {
  const _SearchCall({
    required this.query,
    required this.store,
    required this.brand,
    required this.weight,
    required this.limit,
  });

  final String query;
  final String? store;
  final String? brand;
  final String? weight;
  final int limit;
}

class _FakeOffProductSearchRepository implements OffProductSearchRepository {
  _FakeOffProductSearchRepository({
    this.fallbackResults = const <OffProductSearchResult>[],
    Map<String, List<OffProductSearchResult>> resultsByQuery =
        const <String, List<OffProductSearchResult>>{},
  }) : _resultsByQuery = resultsByQuery;

  final List<OffProductSearchResult> fallbackResults;
  final Map<String, List<OffProductSearchResult>> _resultsByQuery;
  final List<_SearchCall> calls = <_SearchCall>[];

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    calls.add(
      _SearchCall(
        query: query,
        store: store,
        brand: brand,
        weight: weight,
        limit: limit,
      ),
    );
    final results = _resultsByQuery[query] ?? fallbackResults;
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<OffProductSearchResult?> lookupByBarcode({
    required String barcode,
  }) async {
    final results = _resultsByQuery[barcode] ?? fallbackResults;
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return _resultsByQuery[barcode] ?? fallbackResults;
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  String storeName = 'Store',
  String? brand,
  String? weight,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: storeName,
    quantity: 1,
    brand: brand,
    weight: weight,
  );
}

OffProductSearchResult _offResult({
  required String code,
  required String name,
  String? brand,
  String? packageWeight,
  String? imageUrl,
  GlobalFoodNutrition? nutrition,
  double score = 0,
}) {
  return OffProductSearchResult(
    code: code,
    name: name,
    brand: brand,
    packageWeight: packageWeight,
    imageUrl: imageUrl,
    nutrition: nutrition,
    score: score,
  );
}

void main() {
  test('findCandidates skips OFF search for empty names', () async {
    final repository = _FakeOffProductSearchRepository();
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: repository,
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(id: 'item-1', name: '   '),
    );

    expect(candidates, isEmpty);
    expect(repository.calls, isEmpty);
    expect(matcher.defaultSelectionFor(candidates), isNull);
    expect(matcher.defaultSelectionNeedsReviewFor(candidates), isFalse);
  });

  test('findCandidates maps OFF results into review candidates', () async {
    final repository = _FakeOffProductSearchRepository(
      fallbackResults: <OffProductSearchResult>[
        _offResult(
          code: '4061458029995',
          name: 'Waffelhoernchen Haselnuss-Vanille',
          brand: 'Aldi, Froneri, Mucci',
          packageWeight: '110 ml',
          imageUrl:
              'https://images.openfoodfacts.org/images/products/'
              '406/145/802/9995/front_de.3.400.jpg',
          nutrition: const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 215,
          ),
          score: 34,
        ),
      ],
    );
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: repository,
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(
        id: 'item-1',
        name: 'Waffelh Edb/Nuss',
        storeName: 'Aldi Süd',
      ),
    );

    expect(candidates, hasLength(1));
    expect(candidates.first.item.id, 'off-4061458029995');
    expect(candidates.first.reason, GlobalFoodMatchReason.externalSearch);
    expect(candidates.first.requiresPersistence, isTrue);
    expect(candidates.first.score, 77);
    expect(candidates.first.item.imageUrl, isNotNull);
    expect(candidates.first.item.packageWeight, '110 ml');
    expect(candidates.first.item.nutrition?.per100Kcal, 215);
    expect(matcher.defaultSelectionFor(candidates), 'off-4061458029995');
    expect(matcher.defaultSelectionNeedsReviewFor(candidates), isFalse);
  });

  test('findCandidates keeps only the strongest duplicate barcode', () async {
    final repository = _FakeOffProductSearchRepository(
      fallbackResults: <OffProductSearchResult>[
        _offResult(
          code: '4316268538503',
          name: 'Sonnenblumenkerne',
          brand: 'BioBio',
          score: 10,
        ),
        _offResult(
          code: '4316268538503',
          name: 'Sonnenblumenkerne',
          brand: 'BioBio',
          score: 80,
        ),
      ],
    );
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: repository,
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(id: 'item-1', name: 'Sonnenblumenkerne'),
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.item.id, 'off-4316268538503');
    expect(candidates.single.score, 89);
  });

  test(
    'findCandidates dedupes barcode-less results by name and brand',
    () async {
      final repository = _FakeOffProductSearchRepository(
        fallbackResults: <OffProductSearchResult>[
          _offResult(code: '', name: 'Bio Apfel', brand: 'NaturGut', score: 20),
          _offResult(
            code: '   ',
            name: 'BIO APFEL',
            brand: 'naturgut',
            score: 60,
          ),
        ],
      );
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(id: 'item-1', name: 'Bio Apfel'),
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.item.name, 'BIO APFEL');
      expect(candidates.single.item.brand, 'naturgut');
      expect(candidates.single.score, 89);
    },
  );

  test(
    'findCandidates forwards Netto brand and weight to OFF search',
    () async {
      final repository = _FakeOffProductSearchRepository();
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Lasagne Bolognese',
          brand: 'Cucina',
          storeName: 'Netto Marken-Discount',
          weight: '1000 g',
        ),
      );

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.query, 'Lasagne Bolognese');
      expect(repository.calls.single.store, 'Netto');
      expect(repository.calls.single.brand, 'Cucina');
      expect(repository.calls.single.weight, '1000 g');
      expect(repository.calls.single.limit, 20);
    },
  );

  test('findCandidates derives Aldi from the OCR brand when needed', () async {
    final repository = _FakeOffProductSearchRepository();
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: repository,
    );

    await matcher.findCandidates(
      _inventoryItem(
        id: 'item-1',
        name: 'TK Snack-Sortiment',
        brand: 'Aldi Süd',
        storeName: 'Unknown',
      ),
    );

    expect(repository.calls.single.store, 'Aldi');
    expect(repository.calls.single.brand, isNull);
    expect(repository.calls.single.weight, isNull);
  });

  test(
    'findCandidates drops the Netto brand when it only repeats the store',
    () async {
      final repository = _FakeOffProductSearchRepository();
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'R-Hackfleisc',
          brand: 'Netto Marken-Discount',
          storeName: 'Netto',
          weight: '800g',
        ),
      );

      expect(repository.calls.single.store, 'Netto');
      expect(repository.calls.single.brand, isNull);
      expect(repository.calls.single.weight, '800g');
    },
  );

  test(
    'findCandidates forwards brand and optional weight for DE fallback',
    () async {
      final repository = _FakeOffProductSearchRepository();
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Pils Stubbi',
          brand: 'Bitburger',
          storeName: 'Kaufland',
          weight: '20x0.33l',
        ),
      );

      expect(repository.calls.single.store, 'Kaufland');
      expect(repository.calls.single.brand, 'Bitburger');
      expect(repository.calls.single.weight, '20x0.33l');
    },
  );

  test(
    'findCandidates drops fallback brand when it only repeats the store',
    () async {
      final repository = _FakeOffProductSearchRepository();
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Cashews Sour Creme Onion',
          brand: 'Kaufland',
          storeName: 'Kaufland',
        ),
      );

      expect(repository.calls.single.store, 'Kaufland');
      expect(repository.calls.single.brand, isNull);
      expect(repository.calls.single.weight, isNull);
    },
  );

  test(
    'findCandidatesByItemId keeps each OFF response tied to its item',
    () async {
      final repository = _FakeOffProductSearchRepository(
        resultsByQuery: <String, List<OffProductSearchResult>>{
          'Milk': <OffProductSearchResult>[
            _offResult(code: '1', name: 'Milk', score: 80),
          ],
          'Bread': <OffProductSearchResult>[
            _offResult(code: '2', name: 'Bread', score: 70),
          ],
        },
      );
      final matcher = GlobalFoodItemMatcher(
        offProductSearchRepository: repository,
      );

      final results = await matcher.findCandidatesByItemId(<InventoryItem>[
        _inventoryItem(id: 'item-1', name: 'Milk'),
        _inventoryItem(id: 'item-2', name: 'Bread'),
      ]);

      expect(results['item-1']?.single.item.id, 'off-1');
      expect(results['item-2']?.single.item.id, 'off-2');
      expect(
        results['item-1']?.single.item.name,
        isNot(results['item-2']?.single.item.name),
      );
      expect(repository.calls, hasLength(2));
    },
  );
}
