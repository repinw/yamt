import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

@Dependencies([manualProductRecentItemsService])
void main() {
  test('sorts newest manual items first and limits results to six', () {
    final items = List<InventoryItem>.generate(8, (index) {
      return _item(
        id: 'item-$index',
        name: 'Item $index',
        entryDate: DateTime.utc(2026, 1, index + 1),
      );
    });

    final recent = buildManualProductRecentItems(items);

    expect(recent.map((item) => item.id), <String>[
      'item-7',
      'item-6',
      'item-5',
      'item-4',
      'item-3',
      'item-2',
    ]);
  });

  test('dedupes by global id, barcode, and name brand weight key', () {
    final recent = buildManualProductRecentItems(<InventoryItem>[
      _item(
        id: 'old-global',
        name: 'Old global',
        globalFoodItemId: 'global-1',
        entryDate: DateTime.utc(2026),
      ),
      _item(
        id: 'new-global',
        name: 'New global',
        globalFoodItemId: 'global-1',
        entryDate: DateTime.utc(2026, 1, 4),
      ),
      _item(
        id: 'old-barcode',
        name: 'Old barcode',
        barcode: '4006381333931',
        entryDate: DateTime.utc(2026, 1, 2),
      ),
      _item(
        id: 'new-barcode',
        name: 'New barcode',
        barcode: '4006381333931',
        entryDate: DateTime.utc(2026, 1, 5),
      ),
      _item(
        id: 'old-name-key',
        name: 'Milk',
        brand: 'Brand',
        weight: '1 l',
        entryDate: DateTime.utc(2026, 1, 3),
      ),
      _item(
        id: 'new-name-key',
        name: ' milk ',
        brand: ' brand ',
        weight: '1 L',
        entryDate: DateTime.utc(2026, 1, 6),
      ),
    ]);

    expect(recent.map((item) => item.id), <String>[
      'new-name-key',
      'new-barcode',
      'new-global',
    ]);
  });

  test('ignores unsaveable, unnamed, and non-manual items', () {
    final recent = buildManualProductRecentItems(<InventoryItem>[
      _item(id: 'valid', name: 'Valid', entryDate: DateTime.utc(2026, 1, 4)),
      _item(id: 'empty-name', name: '   ', entryDate: DateTime.utc(2026, 1, 5)),
      _item(
        id: 'discount',
        name: 'Discount',
        isDiscount: true,
        entryDate: DateTime.utc(2026, 1, 6),
      ),
      _item(
        id: 'standard',
        name: 'Standard',
        origin: InventoryItemOrigin.standard,
        entryDate: DateTime.utc(2026, 1, 7),
      ),
    ]);

    expect(recent.map((item) => item.id), <String>['valid']);
  });

  test('service provider reads and prepares repository items', () async {
    final repository = _FakeInventoryItemRepository(<InventoryItem>[
      _item(id: 'old', name: 'Old', entryDate: DateTime.utc(2026)),
      _item(id: 'new', name: 'New', entryDate: DateTime.utc(2026, 1, 2)),
    ]);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(manualProductRecentItemsServiceProvider);
    final recent = await service.readRecentItems();

    expect(recent.map((item) => item.id), <String>['new', 'old']);
    expect(repository.readRecentManualLimit, 6);
    expect(repository.didCallReadAll, isFalse);
  });

  test(
    'service limits recent reads when repository has ten thousand items',
    () async {
      final items = List<InventoryItem>.generate(10000, (index) {
        return _item(
          id: 'item-$index',
          name: 'Item $index',
          entryDate: DateTime.utc(2026).add(Duration(seconds: index)),
        );
      }).reversed.toList(growable: false);
      final repository = _FakeInventoryItemRepository(items);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(manualProductRecentItemsServiceProvider);
      final recent = await service.readRecentItems();

      expect(repository.totalItems, 10000);
      expect(repository.readRecentManualLimit, 6);
      expect(repository.readRecentManualReturnedCount, 6);
      expect(repository.didCallReadAll, isFalse);
      expect(recent.map((item) => item.id), <String>[
        'item-9999',
        'item-9998',
        'item-9997',
        'item-9996',
        'item-9995',
        'item-9994',
      ]);
    },
  );

  test('recent item global id hides pending and empty ids', () {
    expect(
      manualProductRecentItemGlobalFoodItemId(
        _item(
          id: 'global',
          name: 'Global',
          globalFoodItemId: 'global-yogurt',
          entryDate: DateTime.utc(2026),
        ),
      ),
      'global-yogurt',
    );
    expect(
      manualProductRecentItemGlobalFoodItemId(
        _item(
          id: 'pending',
          name: 'Pending',
          globalFoodItemId: 'pending-yogurt',
          entryDate: DateTime.utc(2026),
        ),
      ),
      isNull,
    );
    expect(
      manualProductRecentItemGlobalFoodItemId(
        _item(id: 'empty', name: 'Empty', entryDate: DateTime.utc(2026)),
      ),
      isNull,
    );
  });

  test('barcode candidate creates a normalized inventory item', () {
    const nutrition = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 62,
      per100Protein: 3.5,
      per100Carbs: 4.7,
      per100Fat: 3.8,
      per100SaturatedFat: 2.4,
      per100Sugar: 4.7,
      per100Salt: 0.1,
    );
    final baseItem = _item(
      id: 'base',
      name: 'Base',
      entryDate: DateTime.utc(2026),
    );
    final globalFoodItem = GlobalFoodItem.create(
      id: 'global-yogurt',
      name: 'Yogurt',
      brand: 'Dairy',
      category: 'Dairy',
      imageUrl: 'https://example.com/yogurt.png',
      packageWeight: '500 g',
      servingSize: '100 g',
      servingQuantity: 100,
      servingQuantityUnit: 'g',
      nutrition: nutrition,
      now: DateTime.utc(2026),
    );

    final item = inventoryItemFromBarcodeCandidate(
      baseItem: baseItem,
      globalFoodItem: globalFoodItem,
      barcode: ' 4 006381333931 ',
    );

    expect(item.globalFoodItemId, 'global-yogurt');
    expect(item.name, 'Yogurt');
    expect(item.brand, 'Dairy');
    expect(item.category, 'Dairy');
    expect(item.barcode, '4006381333931');
    expect(item.imageUrl, 'https://example.com/yogurt.png');
    expect(item.weight, '500 g');
    expect(item.initialAmount, 500);
    expect(item.currentAmount, 500);
    expect(item.nutrition, nutrition);
  });
}

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  _FakeInventoryItemRepository(this._items);

  final List<InventoryItem> _items;
  int? readRecentManualLimit;
  int? readRecentManualReturnedCount;
  bool didCallReadAll = false;
  int get totalItems => _items.length;

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async {
    didCallReadAll = true;
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    readRecentManualLimit = limit;
    final items = List<InventoryItem>.from(_items.take(limit));
    readRecentManualReturnedCount = items.length;
    return items;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield List<InventoryItem>.from(_items);
  }
}

InventoryItem _item({
  required String id,
  required String name,
  required DateTime entryDate,
  String globalFoodItemId = '',
  String? barcode,
  String? brand,
  String? weight,
  bool isDiscount = false,
  InventoryItemOrigin origin = InventoryItemOrigin.manualAdd,
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: globalFoodItemId,
    name: name,
    brand: brand,
    barcode: barcode,
    weight: weight,
    entryDate: entryDate,
    storeName: 'Store',
    quantity: 1,
    origin: origin,
    isDiscount: isDiscount,
  );
}
