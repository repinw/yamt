import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_recent_items.dart';

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
