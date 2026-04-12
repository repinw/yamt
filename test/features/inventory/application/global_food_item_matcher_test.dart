import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
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

class _GlobalSearchCall {
  const _GlobalSearchCall({
    required this.normalizedName,
    required this.normalizedStoreName,
    required this.barcode,
    required this.foodFingerprint,
    required this.searchTokens,
    required this.limit,
  });

  final String? normalizedName;
  final String? normalizedStoreName;
  final String? barcode;
  final String? foodFingerprint;
  final List<String> searchTokens;
  final int limit;
}

class _AliasSearchCall {
  const _AliasSearchCall({
    required this.normalizedStoreName,
    required this.normalizedReceiptName,
    required this.limit,
  });

  final String normalizedStoreName;
  final String normalizedReceiptName;
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
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return _resultsByQuery[barcode] ?? fallbackResults;
  }
}

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  _FakeGlobalFoodItemRepository({
    this.fallbackResults = const <GlobalFoodItem>[],
    this.onSearch,
  });

  final List<GlobalFoodItem> fallbackResults;
  final Future<List<GlobalFoodItem>> Function(_GlobalSearchCall call)? onSearch;
  final List<_GlobalSearchCall> calls = <_GlobalSearchCall>[];

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    final call = _GlobalSearchCall(
      normalizedName: normalizedName,
      normalizedStoreName: normalizedStoreName,
      barcode: barcode,
      foodFingerprint: foodFingerprint,
      searchTokens: searchTokens,
      limit: limit,
    );
    calls.add(call);
    final results = onSearch == null ? fallbackResults : await onSearch!(call);
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async {
    return true;
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield const <GlobalFoodItem>[];
  }
}

class _FakeGlobalFoodReceiptAliasRepository
    implements GlobalFoodReceiptAliasRepository {
  _FakeGlobalFoodReceiptAliasRepository({
    this.fallbackResults = const <GlobalFoodReceiptAlias>[],
  });

  final List<GlobalFoodReceiptAlias> fallbackResults;
  final List<_AliasSearchCall> calls = <_AliasSearchCall>[];

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) async {
    return true;
  }

  @override
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  }) async {
    calls.add(
      _AliasSearchCall(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
        limit: limit,
      ),
    );
    return fallbackResults.take(limit).toList(growable: false);
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  String storeName = 'Store',
  String? brand,
  String? ocrName,
  String? weight,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: storeName,
    quantity: 1,
    brand: brand,
    ocrName: ocrName,
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

GlobalFoodItem _globalItem({
  required String id,
  required String name,
  String? storeName,
  String? brand,
  String? barcode,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    storeName: storeName,
    brand: brand,
    barcode: barcode,
    now: DateTime.parse('2026-03-01T10:00:00Z'),
  );
}

GlobalFoodReceiptAlias _receiptAlias({
  required String id,
  required String receiptName,
  required GlobalFoodItem item,
  required int selectionCount,
}) {
  return GlobalFoodReceiptAlias.tryCreate(
    storeName: item.storeName ?? 'Aldi',
    receiptName: receiptName,
    globalFoodItem: item,
    now: DateTime.parse('2026-03-01T11:00:00Z'),
  )!.copyWith(
    id: id,
    selectionCount: selectionCount,
    updatedAt: DateTime.parse('2026-03-01T11:00:00Z'),
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
          name: 'Waffelhörnchen Haselnuss-Vanille',
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

  test(
    'findCandidates queries global items and still keeps OFF candidates',
    () async {
      final globalRepository = _FakeGlobalFoodItemRepository(
        fallbackResults: <GlobalFoodItem>[
          _globalItem(
            id: 'global-1',
            name: 'Whole Milk',
            storeName: 'Aldi',
            brand: 'Milsani',
            barcode: '111',
          ),
        ],
      );
      final offRepository = _FakeOffProductSearchRepository(
        fallbackResults: <OffProductSearchResult>[
          _offResult(
            code: '222',
            name: 'Whole Milk',
            brand: 'Milsani',
            score: 20,
          ),
        ],
      );
      final matcher = GlobalFoodItemMatcher(
        globalFoodItemRepository: globalRepository,
        offProductSearchRepository: offRepository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Whole Milk',
          brand: 'Milsani',
          storeName: 'Aldi Süd',
        ),
      );

      expect(globalRepository.calls, hasLength(1));
      expect(globalRepository.calls.single.normalizedName, 'whole milk');
      expect(globalRepository.calls.single.normalizedStoreName, 'aldi');
      expect(offRepository.calls, hasLength(1));
      expect(candidates, hasLength(2));
      expect(candidates.first.item.id, 'global-1');
      expect(candidates.first.requiresPersistence, isFalse);
      expect(candidates.last.item.id, 'off-222');
      expect(candidates.last.requiresPersistence, isTrue);
    },
  );

  test(
    'findCandidates puts receipt alias matches ahead of generic global matches',
    () async {
      final aliasMilk = _globalItem(
        id: 'alias-milk',
        name: 'Whole Milk',
        storeName: 'Aldi',
        brand: 'Milsani',
      );
      final aliasRepository = _FakeGlobalFoodReceiptAliasRepository(
        fallbackResults: <GlobalFoodReceiptAlias>[
          _receiptAlias(
            id: 'alias-1',
            receiptName: 'MLK 3.5%',
            item: aliasMilk,
            selectionCount: 5,
          ),
        ],
      );
      final globalRepository = _FakeGlobalFoodItemRepository(
        fallbackResults: <GlobalFoodItem>[
          _globalItem(
            id: 'global-milk',
            name: 'Milch 3,5%',
            storeName: 'Aldi',
            brand: 'OwnBrand',
          ),
        ],
      );
      final matcher = GlobalFoodItemMatcher(
        globalFoodItemRepository: globalRepository,
        globalFoodReceiptAliasRepository: aliasRepository,
        offProductSearchRepository: _FakeOffProductSearchRepository(),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Milch 3,5%',
          ocrName: 'MLK 3.5%',
          brand: 'Milsani',
          storeName: 'ALDI SUED',
        ),
      );

      expect(aliasRepository.calls, hasLength(1));
      expect(aliasRepository.calls.single.normalizedStoreName, 'aldi');
      expect(aliasRepository.calls.single.normalizedReceiptName, 'mlk 3 5');
      expect(candidates, hasLength(2));
      expect(candidates.first.item.id, 'alias-milk');
      expect(candidates.first.reason, GlobalFoodMatchReason.receiptAliasExact);
      expect(candidates[1].item.id, 'global-milk');
    },
  );

  test('findCandidates ranks more frequently chosen aliases higher', () async {
    final lessChosen = _globalItem(
      id: 'milk-low',
      name: 'Whole Milk',
      storeName: 'Aldi',
      brand: 'Milsani',
      barcode: '111',
    );
    final moreChosen = _globalItem(
      id: 'milk-high',
      name: 'Whole Milk',
      storeName: 'Aldi',
      brand: 'Milsani',
      barcode: '222',
    );
    final aliasRepository = _FakeGlobalFoodReceiptAliasRepository(
      fallbackResults: <GlobalFoodReceiptAlias>[
        _receiptAlias(
          id: 'alias-low',
          receiptName: 'MLK 3.5%',
          item: lessChosen,
          selectionCount: 2,
        ),
        _receiptAlias(
          id: 'alias-high',
          receiptName: 'MLK 3.5%',
          item: moreChosen,
          selectionCount: 8,
        ),
      ],
    );
    final matcher = GlobalFoodItemMatcher(
      globalFoodReceiptAliasRepository: aliasRepository,
      offProductSearchRepository: _FakeOffProductSearchRepository(),
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(
        id: 'item-1',
        name: 'Milch 3,5%',
        ocrName: 'MLK 3.5%',
        storeName: 'Aldi',
      ),
    );

    expect(candidates.take(2).map((item) => item.item.id), <String>[
      'milk-high',
      'milk-low',
    ]);
  });

  test(
    'findCandidates keeps local and OFF buckets separate even for same barcode',
    () async {
      final globalRepository = _FakeGlobalFoodItemRepository(
        fallbackResults: <GlobalFoodItem>[
          _globalItem(
            id: 'global-111',
            name: 'Whole Milk',
            storeName: 'Aldi',
            brand: 'Milsani',
            barcode: '111',
          ),
        ],
      );
      final offRepository = _FakeOffProductSearchRepository(
        fallbackResults: <OffProductSearchResult>[
          _offResult(
            code: '111',
            name: 'Whole Milk',
            brand: 'Milsani',
            score: 80,
          ),
        ],
      );
      final matcher = GlobalFoodItemMatcher(
        globalFoodItemRepository: globalRepository,
        offProductSearchRepository: offRepository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Whole Milk',
          brand: 'Milsani',
          storeName: 'Aldi',
        ),
      );

      expect(candidates, hasLength(2));
      expect(candidates.first.item.id, 'global-111');
      expect(candidates.first.requiresPersistence, isFalse);
      expect(candidates.last.item.id, 'off-111');
      expect(candidates.last.requiresPersistence, isTrue);
    },
  );

  test(
    'findCandidates prefers same-store local matches over other stores',
    () async {
      final globalRepository = _FakeGlobalFoodItemRepository(
        fallbackResults: <GlobalFoodItem>[
          _globalItem(
            id: 'aldi-milk',
            name: 'Whole Milk',
            storeName: 'Aldi',
            brand: 'Milsani',
          ),
          _globalItem(
            id: 'lidl-milk',
            name: 'Whole Milk',
            storeName: 'Lidl',
            brand: 'Milsani',
          ),
        ],
      );
      final matcher = GlobalFoodItemMatcher(
        globalFoodItemRepository: globalRepository,
        offProductSearchRepository: _FakeOffProductSearchRepository(),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Whole Milk',
          brand: 'Milsani',
          storeName: 'ALDI SUED',
        ),
      );

      expect(candidates, hasLength(1));
      expect(candidates.first.item.id, 'aldi-milk');
      expect(matcher.defaultSelectionFor(candidates), 'aldi-milk');
    },
  );

  test(
    'findCandidates returns at most five local and five OFF candidates',
    () async {
      final globalRepository = _FakeGlobalFoodItemRepository(
        fallbackResults: List<GlobalFoodItem>.generate(
          6,
          (index) => _globalItem(
            id: 'global-$index',
            name: 'Whole Milk $index',
            storeName: 'Aldi',
            brand: 'Brand $index',
          ),
        ),
      );
      final offRepository = _FakeOffProductSearchRepository(
        fallbackResults: List<OffProductSearchResult>.generate(
          6,
          (index) => _offResult(
            code: '200$index',
            name: 'Whole Milk OFF $index',
            brand: 'OffBrand $index',
            score: 90 - index.toDouble(),
          ),
        ),
      );
      final matcher = GlobalFoodItemMatcher(
        globalFoodItemRepository: globalRepository,
        offProductSearchRepository: offRepository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Whole Milk',
          brand: 'Milsani',
          storeName: 'Aldi',
        ),
      );

      expect(candidates, hasLength(10));
      expect(
        candidates.take(5).every((candidate) => !candidate.requiresPersistence),
        isTrue,
      );
      expect(
        candidates.skip(5).every((candidate) => candidate.requiresPersistence),
        isTrue,
      );
    },
  );

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
