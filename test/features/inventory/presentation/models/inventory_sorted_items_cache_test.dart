import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_sorted_items_cache.dart';

InventoryItem _item({
  required String id,
  required String name,
  required String entryDate,
  int quantity = 1,
  int initialQuantity = 1,
  String? lastConsumedAt,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse(entryDate),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1.0,
    lastConsumedAt: lastConsumedAt == null
        ? null
        : DateTime.parse(lastConsumedAt),
  );
}

void main() {
  test('update returns same instance for unchanged signature', () {
    final items = <InventoryItem>[
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-21T08:00:00Z'),
    ];
    final cache = InventorySortedItemsCache.fromItems(items);

    final next = cache.update(List<InventoryItem>.from(items));
    expect(identical(next, cache), isTrue);
  });

  test('update returns new instance for cache misses', () {
    final base = <InventoryItem>[
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-21T08:00:00Z'),
    ];
    final cache = InventorySortedItemsCache.fromItems(base);

    final added = cache.update(<InventoryItem>[
      ...base,
      _item(id: 'c', name: 'Cherry', entryDate: '2026-02-22T08:00:00Z'),
    ]);
    final removed = cache.update(<InventoryItem>[base.first]);
    final changed = cache.update(<InventoryItem>[
      base.first.copyWith(name: 'Apricot'),
      base.last,
    ]);

    expect(identical(added, cache), isFalse);
    expect(identical(removed, cache), isFalse);
    expect(identical(changed, cache), isFalse);
  });

  test('materialize restores cached sorted order', () {
    final a = _item(
      id: 'a',
      name: 'Banana',
      entryDate: '2026-02-20T08:00:00Z',
      quantity: 4,
      initialQuantity: 4,
    );
    final b = _item(
      id: 'b',
      name: 'Apple',
      entryDate: '2026-02-20T08:00:00Z',
      quantity: 0,
      initialQuantity: 4,
      lastConsumedAt: '2026-02-22T08:00:00Z',
    );
    final c = _item(
      id: 'c',
      name: 'Apple',
      entryDate: '2026-02-21T08:00:00Z',
      quantity: 2,
      initialQuantity: 4,
      lastConsumedAt: '2026-02-21T12:00:00Z',
    );
    final cache = InventorySortedItemsCache.fromItems(<InventoryItem>[a, b, c]);

    final materialized = cache.materialize(<InventoryItem>[c, a, b]);
    expect(materialized.map((item) => item.id), <String>['c', 'a', 'b']);
  });

  test('compare sort order keeps partial items first and empty last', () {
    final partialOlder = _item(
      id: 'partial-older',
      name: 'Apple',
      entryDate: '2026-02-20T08:00:00Z',
      quantity: 2,
      initialQuantity: 4,
      lastConsumedAt: '2026-02-21T08:00:00Z',
    );
    final partialNewer = _item(
      id: 'partial-newer',
      name: 'Banana',
      entryDate: '2026-02-22T08:00:00Z',
      quantity: 1,
      initialQuantity: 4,
      lastConsumedAt: '2026-02-22T10:00:00Z',
    );
    final full = _item(
      id: 'full',
      name: 'Apricot',
      entryDate: '2026-02-23T08:00:00Z',
      quantity: 4,
      initialQuantity: 4,
    );
    final empty = _item(
      id: 'empty',
      name: 'Cherry',
      entryDate: '2026-02-24T08:00:00Z',
      quantity: 0,
      initialQuantity: 4,
      lastConsumedAt: '2026-02-24T09:00:00Z',
    );

    final sorted = sortInventoryItems(<InventoryItem>[
      empty,
      full,
      partialOlder,
      partialNewer,
    ]);

    expect(sorted.map((item) => item.id), <String>[
      'partial-newer',
      'partial-older',
      'full',
      'empty',
    ]);
  });
}
