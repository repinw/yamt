import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';

FridgeItem _item({
  required String id,
  required String name,
  required String entryDate,
}) {
  return FridgeItem(
    id: id,
    name: name,
    entryDate: DateTime.parse(entryDate),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

void main() {
  test('update returns same instance for unchanged signature', () {
    final items = <FridgeItem>[
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-21T08:00:00Z'),
    ];
    final cache = InventorySortedItemsCache.fromItems(items);

    final next = cache.update(List<FridgeItem>.from(items));
    expect(identical(next, cache), isTrue);
  });

  test('update returns new instance for cache misses', () {
    final base = <FridgeItem>[
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-21T08:00:00Z'),
    ];
    final cache = InventorySortedItemsCache.fromItems(base);

    final added = cache.update(<FridgeItem>[
      ...base,
      _item(id: 'c', name: 'Cherry', entryDate: '2026-02-22T08:00:00Z'),
    ]);
    final removed = cache.update(<FridgeItem>[base.first]);
    final changed = cache.update(<FridgeItem>[
      base.first.copyWith(name: 'Apricot'),
      base.last,
    ]);

    expect(identical(added, cache), isFalse);
    expect(identical(removed, cache), isFalse);
    expect(identical(changed, cache), isFalse);
  });

  test('materialize restores cached sorted order', () {
    final a = _item(id: 'a', name: 'Banana', entryDate: '2026-02-20T08:00:00Z');
    final b = _item(id: 'b', name: 'Apple', entryDate: '2026-02-20T08:00:00Z');
    final c = _item(id: 'c', name: 'Apple', entryDate: '2026-02-21T08:00:00Z');
    final cache = InventorySortedItemsCache.fromItems(<FridgeItem>[a, b, c]);

    final materialized = cache.materialize(<FridgeItem>[c, a, b]);
    expect(materialized.map((item) => item.id), <String>['c', 'b', 'a']);
  });

  test('compare sort order is name then date then id', () {
    final newerApple = _item(
      id: 'apple-new',
      name: 'Apple',
      entryDate: '2026-02-21T08:00:00Z',
    );
    final olderAppleB = _item(
      id: 'b-id',
      name: 'Apple',
      entryDate: '2026-02-20T08:00:00Z',
    );
    final olderAppleA = _item(
      id: 'a-id',
      name: 'Apple',
      entryDate: '2026-02-20T08:00:00Z',
    );
    final banana = _item(
      id: 'banana',
      name: 'Banana',
      entryDate: '2026-02-22T08:00:00Z',
    );

    final sorted = sortInventoryItems(<FridgeItem>[
      banana,
      olderAppleB,
      newerApple,
      olderAppleA,
    ]);

    expect(sorted.map((item) => item.id), <String>[
      'apple-new',
      'a-id',
      'b-id',
      'banana',
    ]);
  });
}
