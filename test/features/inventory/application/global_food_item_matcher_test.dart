import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  _FakeGlobalFoodItemRepository(this.items);

  final List<GlobalFoodItem> items;
  int readAllCalls = 0;
  int searchCalls = 0;
  String? lastNormalizedName;
  String? lastBarcode;
  String? lastFoodFingerprint;
  List<String> lastSearchTokens = const <String>[];

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    readAllCalls += 1;
    return items;
  }

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    searchCalls += 1;
    lastNormalizedName = normalizedName;
    lastBarcode = barcode;
    lastFoodFingerprint = foodFingerprint;
    lastSearchTokens = List<String>.from(searchTokens);

    return items
        .where(
          (item) =>
              (normalizedName != null &&
                  item.normalizedName == normalizedName) ||
              (barcode != null && item.normalizedBarcode == barcode) ||
              (foodFingerprint != null &&
                  item.resolvedFoodFingerprint == foodFingerprint) ||
              item.searchTokens.any(searchTokens.contains),
        )
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository(this.items);

  final List<InventoryItem> items;
  int readAllCalls = 0;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    readAllCalls += 1;
    return items;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _FakeCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  _FakeCalorieProductCacheRepository({
    Map<String, CalorieProductProfile> profiles =
        const <String, CalorieProductProfile>{},
  }) : userOverrides = profiles,
       globalProducts = profiles;

  final Map<String, CalorieProductProfile> userOverrides;
  final Map<String, CalorieProductProfile> globalProducts;

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    return userOverrides[barcode];
  }

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    return globalProducts[barcode];
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async => true;

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async => true;
}

class _FakeOffProductSearchRepository implements OffProductSearchRepository {
  _FakeOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastQuery;
  String? lastStore;
  String? lastBrand;
  String? lastWeight;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    lastQuery = query;
    lastStore = store;
    lastBrand = brand;
    lastWeight = weight;
    return results.take(limit).toList(growable: false);
  }
}

GlobalFoodItem _globalFood({
  required String id,
  required String name,
  String? brand,
  String? barcode,
  String? imageUrl,
  String? foodFingerprint,
  GlobalFoodItemStatus status = GlobalFoodItemStatus.active,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    now: DateTime.parse('2026-03-01T10:00:00Z'),
    brand: brand,
    barcode: barcode,
    imageUrl: imageUrl,
    foodFingerprint: foodFingerprint,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
    ),
    status: status,
  );
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  String? brand,
  String storeName = 'Store',
  String? weight,
  String? globalFoodItemId,
  String? barcode,
  String? imageUrl,
  String? foodFingerprint,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: storeName,
    quantity: 1,
    brand: brand,
    weight: weight,
    barcode: barcode,
    imageUrl: imageUrl,
    foodFingerprint: foodFingerprint,
    globalFoodItemId: globalFoodItemId,
  );
}

CalorieProductProfile _calorieProfile({
  required String barcode,
  required String name,
  String? brand,
  double per100Kcal = 64,
  double per100Protein = 1.2,
  double per100Carbs = 11.4,
  double per100Fat = 0.2,
}) {
  return CalorieProductProfile(
    barcode: barcode,
    name: name,
    brand: brand,
    per100Kcal: per100Kcal,
    per100Protein: per100Protein,
    per100Carbs: per100Carbs,
    per100Fat: per100Fat,
    source: CalorieProductSource.globalCatalog,
    createdAt: DateTime.parse('2026-03-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-03-01T10:00:00Z'),
  );
}

void main() {
  test('findCandidates prefers exact fingerprint matches', () async {
    final repository = _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
      _globalFood(
        id: 'milk',
        name: 'Milk',
        brand: 'Acme',
        foodFingerprint: 'milk__acme',
      ),
      _globalFood(id: 'bread', name: 'Bread', brand: 'Acme'),
    ]);
    final matcher = GlobalFoodItemMatcher(repository: repository);

    final candidates = await matcher.findCandidates(
      _inventoryItem(
        id: 'item-1',
        name: 'Milk',
        brand: 'Acme',
        foodFingerprint: 'milk__acme',
      ),
    );

    expect(candidates, isNotEmpty);
    expect(candidates.first.item.id, 'milk');
    expect(candidates.first.reason, GlobalFoodMatchReason.fingerprintExact);
    expect(matcher.defaultSelectionFor(candidates), 'milk');
    expect(matcher.defaultSelectionNeedsReviewFor(candidates), isFalse);
    expect(repository.searchCalls, 1);
    expect(repository.readAllCalls, 0);
    expect(repository.lastNormalizedName, 'milk');
    expect(repository.lastFoodFingerprint, 'milk__acme');
    expect(repository.lastSearchTokens, contains('milk'));
    expect(repository.lastSearchTokens, isNot(contains('acme')));
  });

  test(
    'findCandidates does not query inventory when search returns nothing',
    () async {
      final repository = _FakeGlobalFoodItemRepository(
        const <GlobalFoodItem>[],
      );
      final inventoryRepository = _FakeInventoryItemRepository(<InventoryItem>[
        _inventoryItem(id: 'known', name: 'Milk'),
      ]);
      final matcher = GlobalFoodItemMatcher(
        repository: repository,
        inventoryRepository: inventoryRepository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(id: 'item-1', name: 'Milk', brand: 'Acme'),
      );

      expect(candidates, isEmpty);
      expect(repository.searchCalls, 1);
      expect(inventoryRepository.readAllCalls, 0);
    },
  );

  test(
    'findCandidates skips repository queries for empty search input',
    () async {
      final repository = _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
        _globalFood(id: 'milk', name: 'Milk', brand: 'Acme'),
      ]);
      final matcher = GlobalFoodItemMatcher(repository: repository);

      final candidates = await matcher.findCandidates(
        _inventoryItem(id: 'item-1', name: ' '),
      );

      expect(candidates, isEmpty);
      expect(repository.searchCalls, 0);
      expect(repository.readAllCalls, 0);
    },
  );

  test(
    'findCandidates enriches products from existing inventory items',
    () async {
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
          _globalFood(
            id: 'milk',
            name: 'Milk',
            brand: 'Acme',
            foodFingerprint: 'milk__acme',
          ),
        ]),
        inventoryRepository: _FakeInventoryItemRepository(<InventoryItem>[
          _inventoryItem(
            id: 'known-item',
            name: 'Milk',
            brand: 'Acme',
            globalFoodItemId: 'milk',
            barcode: '4006381333931',
            imageUrl: 'https://example.com/milk.png',
            foodFingerprint: 'milk__acme',
          ),
        ]),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'new-item',
          name: 'Milk',
          brand: 'Acme',
          foodFingerprint: 'milk__acme',
        ),
      );

      expect(candidates.single.item.normalizedBarcode, '4006381333931');
      expect(candidates.single.item.imageUrl, 'https://example.com/milk.png');
    },
  );

  test(
    'findCandidates enriches missing nutrition from calorie catalog',
    () async {
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
          GlobalFoodItem.create(
            id: 'apple',
            name: 'Bio Apfel Gala',
            brand: 'NaturGut',
            barcode: '4006381333931',
            now: DateTime.parse('2026-03-01T10:00:00Z'),
          ),
        ]),
        calorieProductCacheRepository: _FakeCalorieProductCacheRepository(
          profiles: <String, CalorieProductProfile>{
            '4006381333931': _calorieProfile(
              barcode: '4006381333931',
              name: 'Bio Apfel Gala',
              brand: 'NaturGut',
              per100Kcal: 52,
              per100Protein: 0.3,
              per100Carbs: 11.4,
              per100Fat: 0.2,
            ),
          },
        ),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(id: 'item-1', name: 'Bio Apfel Gala', brand: 'NaturGut'),
      );

      expect(candidates, isNotEmpty);
      expect(candidates.single.item.nutrition, isNotNull);
      expect(candidates.single.item.nutrition!.per100Kcal, 52);
      expect(candidates.single.item.nutrition!.per100Carbs, 11.4);
      expect(candidates.single.item.nutrition!.per100Protein, 0.3);
      expect(candidates.single.item.nutrition!.per100Fat, 0.2);
    },
  );

  test('findCandidates skips merged products and weak matches', () async {
    final matcher = GlobalFoodItemMatcher(
      repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
        _globalFood(
          id: 'merged',
          name: 'Milk',
          brand: 'Acme',
          status: GlobalFoodItemStatus.merged,
        ),
        _globalFood(id: 'water', name: 'Sparkling Water', brand: 'Brand'),
      ]),
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(id: 'item-1', name: 'Milk', brand: 'Acme'),
    );

    expect(candidates, isEmpty);
    expect(matcher.defaultSelectionFor(candidates), isNull);
    expect(matcher.defaultSelectionNeedsReviewFor(candidates), isFalse);
  });

  test(
    'default selection stays empty for token-only Firebase matches',
    () async {
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
          _globalFood(id: 'gouda', name: 'Gouda in Scheiben', brand: 'Milbona'),
          _globalFood(
            id: 'edamer',
            name: 'Edamer in Scheiben',
            brand: 'Milbona',
          ),
        ]),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'KÄSE SCHEIBEN 150G',
          brand: 'Milbona',
        ),
      );

      expect(candidates, isNotEmpty);
      expect(matcher.defaultSelectionFor(candidates), isNull);
      expect(matcher.defaultSelectionNeedsReviewFor(candidates), isTrue);
    },
  );

  test(
    'default selection auto-selects unique exact Firebase name match',
    () async {
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
          _globalFood(id: 'gouda', name: 'Gouda in Scheiben'),
        ]),
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(id: 'item-1', name: 'Gouda in Scheiben'),
      );

      expect(candidates, hasLength(1));
      expect(
        candidates.first.reason,
        isIn(<GlobalFoodMatchReason>[
          GlobalFoodMatchReason.fingerprintExact,
          GlobalFoodMatchReason.nameExact,
        ]),
      );
      expect(matcher.defaultSelectionFor(candidates), 'gouda');
      expect(matcher.defaultSelectionNeedsReviewFor(candidates), isFalse);
    },
  );

  test('findCandidates does not surface brand-only Firebase hits', () async {
    final matcher = GlobalFoodItemMatcher(
      repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
        _globalFood(id: 'bread', name: 'Eiweissbrot', brand: 'Kornmark'),
      ]),
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(id: 'item-1', name: 'Tomatensauce', brand: 'Kornmark'),
    );

    expect(candidates, isEmpty);
  });

  test(
    'findCandidates includes external OFF search results for review',
    () async {
      final externalRepository =
          _FakeOffProductSearchRepository(<OffProductSearchResult>[
            const OffProductSearchResult(
              code: '4061458029995',
              name: 'Waffelhoernchen Haselnuss-Vanille',
              brand: 'Aldi, Froneri, Mucci',
              packageWeight: '110 ml',
              imageUrl:
                  'https://images.openfoodfacts.org/images/products/'
                  '406/145/802/9995/front_de.3.400.jpg',
              nutrition: GlobalFoodNutrition(
                qualityStatus: GlobalFoodNutritionQualityStatus.verified,
                per100Kcal: 215,
                per100Protein: 4.2,
                per100Carbs: 24.8,
                per100Fat: 9.6,
                per100Salt: 0.4,
              ),
              score: 34,
            ),
          ]);
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(const <GlobalFoodItem>[]),
        offProductSearchRepository: externalRepository,
      );

      final candidates = await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'Waffelh Edb/Nuss',
          storeName: 'Aldi Süd',
        ),
      );

      expect(candidates, isNotEmpty);
      expect(candidates.first.item.id, 'off-4061458029995');
      expect(candidates.first.reason, GlobalFoodMatchReason.externalSearch);
      expect(candidates.first.requiresPersistence, isTrue);
      expect(candidates.first.item.normalizedBarcode, '4061458029995');
      expect(
        candidates.first.item.imageUrl,
        'https://images.openfoodfacts.org/images/products/'
        '406/145/802/9995/front_de.3.400.jpg',
      );
      expect(candidates.first.item.packageWeight, '110 ml');
      expect(candidates.first.item.nutrition, isNotNull);
      expect(candidates.first.item.nutrition!.per100Kcal, 215);
      expect(matcher.defaultSelectionNeedsReviewFor(candidates), isTrue);
      expect(externalRepository.lastQuery, 'Waffelh Edb/Nuss');
      expect(externalRepository.lastStore, 'Aldi');
      expect(externalRepository.lastBrand, isNull);
      expect(externalRepository.lastWeight, isNull);
    },
  );

  test('findCandidates keeps Firebase matches before OFF candidates', () async {
    final repository = _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
      _globalFood(
        id: 'firebase-1',
        name: 'Lasagne Bolognese',
        brand: 'Cucina',
        barcode: '4099365169629',
      ),
    ]);
    final externalRepository =
        _FakeOffProductSearchRepository(const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4099365169629',
            name: 'Lasagne Bolognese',
            brand: 'Aldi, Condeli, Cucina',
            score: 99,
          ),
        ]);
    final matcher = GlobalFoodItemMatcher(
      repository: repository,
      offProductSearchRepository: externalRepository,
    );

    final candidates = await matcher.findCandidates(
      _inventoryItem(
        id: 'item-1',
        name: 'Lasagne Bolognese',
        brand: 'Cucina',
        storeName: 'Aldi Süd',
      ),
    );

    expect(candidates, hasLength(1));
    expect(candidates.first.item.id, 'firebase-1');
    expect(
      candidates.first.reason,
      isNot(GlobalFoodMatchReason.externalSearch),
    );
  });

  test(
    'findCandidates forwards Netto brand and weight to OFF search',
    () async {
      final externalRepository = _FakeOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(const <GlobalFoodItem>[]),
        offProductSearchRepository: externalRepository,
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

      expect(externalRepository.lastQuery, 'Lasagne Bolognese');
      expect(externalRepository.lastStore, 'Netto');
      expect(externalRepository.lastBrand, 'Cucina');
      expect(externalRepository.lastWeight, '1000 g');
    },
  );

  test(
    'findCandidates derives Aldi store from brand when store is unknown',
    () async {
      final externalRepository = _FakeOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(const <GlobalFoodItem>[]),
        offProductSearchRepository: externalRepository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'TK Snack-Sortiment',
          brand: 'Aldi Süd',
          storeName: 'Unknown',
        ),
      );

      expect(externalRepository.lastQuery, 'TK Snack-Sortiment');
      expect(externalRepository.lastStore, 'Aldi');
      expect(externalRepository.lastBrand, isNull);
      expect(externalRepository.lastWeight, isNull);
    },
  );

  test(
    'findCandidates ignores Netto brand when it repeats the store',
    () async {
      final externalRepository = _FakeOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(const <GlobalFoodItem>[]),
        offProductSearchRepository: externalRepository,
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

      expect(externalRepository.lastQuery, 'R-Hackfleisc');
      expect(externalRepository.lastStore, 'Netto');
      expect(externalRepository.lastBrand, isNull);
      expect(externalRepository.lastWeight, '800g');
    },
  );

  test(
    'findCandidates derives Netto store from brand when store is unknown',
    () async {
      final externalRepository = _FakeOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );
      final matcher = GlobalFoodItemMatcher(
        repository: _FakeGlobalFoodItemRepository(const <GlobalFoodItem>[]),
        offProductSearchRepository: externalRepository,
      );

      await matcher.findCandidates(
        _inventoryItem(
          id: 'item-1',
          name: 'R-Hackfleisc',
          brand: 'Netto Marken-Discount',
          storeName: 'Unknown',
          weight: '800g',
        ),
      );

      expect(externalRepository.lastQuery, 'R-Hackfleisc');
      expect(externalRepository.lastStore, 'Netto');
      expect(externalRepository.lastBrand, isNull);
      expect(externalRepository.lastWeight, '800g');
    },
  );

  test(
    'findCandidatesByItemId loads enrichment data once for a batch',
    () async {
      final repository = _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
        _globalFood(id: 'milk', name: 'Milk'),
        _globalFood(id: 'bread', name: 'Bread'),
      ]);
      final inventoryRepository = _FakeInventoryItemRepository(
        const <InventoryItem>[],
      );
      final matcher = GlobalFoodItemMatcher(
        repository: repository,
        inventoryRepository: inventoryRepository,
        offProductSearchRepository: _FakeOffProductSearchRepository(
          const <OffProductSearchResult>[],
        ),
      );

      final results = await matcher.findCandidatesByItemId(<InventoryItem>[
        _inventoryItem(id: 'item-1', name: 'Milk'),
        _inventoryItem(id: 'item-2', name: 'Bread'),
      ]);

      expect(results.keys, containsAll(<String>['item-1', 'item-2']));
      expect(inventoryRepository.readAllCalls, 1);
    },
  );
}
