import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  _FakeGlobalFoodItemRepository(this.items);

  final List<GlobalFoodItem> items;

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async => items;

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository(this.items);

  final List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<InventoryItem>> readAll() async => items;

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
  String? globalFoodItemId,
  String? barcode,
  String? imageUrl,
  String? foodFingerprint,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    brand: brand,
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
    final matcher = GlobalFoodItemMatcher(
      repository: _FakeGlobalFoodItemRepository(<GlobalFoodItem>[
        _globalFood(
          id: 'milk',
          name: 'Milk',
          brand: 'Acme',
          foodFingerprint: 'milk__acme',
        ),
        _globalFood(id: 'bread', name: 'Bread', brand: 'Acme'),
      ]),
    );

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
  });

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
    'default selection keeps best candidate but marks review for ambiguity',
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
      expect(matcher.defaultSelectionFor(candidates), isNotNull);
      expect(matcher.defaultSelectionNeedsReviewFor(candidates), isTrue);
    },
  );
}
