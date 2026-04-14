import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
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
    final cache = InventorySortedItemsCache.fromItems(
      items,
      sortMode: InventoryItemSortMode.recentlyAddedDescending,
    );

    final next = cache.update(
      List<InventoryItem>.from(items),
      sortMode: InventoryItemSortMode.recentlyAddedDescending,
    );
    expect(identical(next, cache), isTrue);
  });

  test('update returns new instance for cache misses', () {
    final base = <InventoryItem>[
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-21T08:00:00Z'),
    ];
    final cache = InventorySortedItemsCache.fromItems(
      base,
      sortMode: InventoryItemSortMode.recentlyAddedDescending,
    );

    final added = cache.update(<InventoryItem>[
      ...base,
      _item(id: 'c', name: 'Cherry', entryDate: '2026-02-22T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.recentlyAddedDescending);
    final removed = cache.update(<InventoryItem>[
      base.first,
    ], sortMode: InventoryItemSortMode.recentlyAddedDescending);
    final changed = cache.update(<InventoryItem>[
      base.first.copyWith(name: 'Apricot'),
      base.last,
    ], sortMode: InventoryItemSortMode.recentlyAddedDescending);
    final differentSortMode = cache.update(
      base,
      sortMode: InventoryItemSortMode.alphabeticalAscending,
    );

    expect(identical(added, cache), isFalse);
    expect(identical(removed, cache), isFalse);
    expect(identical(changed, cache), isFalse);
    expect(identical(differentSortMode, cache), isFalse);
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
    final cache = InventorySortedItemsCache.fromItems(<InventoryItem>[
      a,
      b,
      c,
    ], sortMode: InventoryItemSortMode.recentlyAddedDescending);

    final materialized = cache.materialize(<InventoryItem>[c, a, b]);
    expect(materialized.map((item) => item.id), <String>['c', 'b', 'a']);
  });

  test('recently added sorts support descending and ascending', () {
    final sorted = sortInventoryItems(<InventoryItem>[
      _item(id: 'older', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'newer', name: 'Banana', entryDate: '2026-02-22T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.recentlyAddedDescending);
    final ascending = sortInventoryItems(<InventoryItem>[
      _item(id: 'older', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'newer', name: 'Banana', entryDate: '2026-02-22T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.recentlyAddedAscending);

    expect(sorted.map((item) => item.id), <String>['newer', 'older']);
    expect(ascending.map((item) => item.id), <String>['older', 'newer']);
  });

  test('recently eaten sorts support descending and ascending', () {
    final descending = sortInventoryItems(<InventoryItem>[
      _item(
        id: 'old',
        name: 'Old',
        entryDate: '2026-02-20T08:00:00Z',
        lastConsumedAt: '2026-02-21T08:00:00Z',
      ),
      _item(
        id: 'recent',
        name: 'Recent',
        entryDate: '2026-02-21T08:00:00Z',
        lastConsumedAt: '2026-02-22T08:00:00Z',
      ),
      _item(id: 'never', name: 'Never', entryDate: '2026-02-22T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.recentlyEatenDescending);
    final ascending = sortInventoryItems(<InventoryItem>[
      _item(
        id: 'old',
        name: 'Old',
        entryDate: '2026-02-20T08:00:00Z',
        lastConsumedAt: '2026-02-21T08:00:00Z',
      ),
      _item(
        id: 'recent',
        name: 'Recent',
        entryDate: '2026-02-21T08:00:00Z',
        lastConsumedAt: '2026-02-22T08:00:00Z',
      ),
      _item(id: 'never', name: 'Never', entryDate: '2026-02-22T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.recentlyEatenAscending);

    expect(descending.map((item) => item.id), <String>[
      'recent',
      'old',
      'never',
    ]);
    expect(ascending.map((item) => item.id), <String>[
      'old',
      'recent',
      'never',
    ]);
  });

  test('alphabetical sort orders by item name both directions', () {
    final ascending = sortInventoryItems(<InventoryItem>[
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-22T08:00:00Z'),
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'c', name: 'Cherry', entryDate: '2026-02-21T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.alphabeticalAscending);
    final descending = sortInventoryItems(<InventoryItem>[
      _item(id: 'b', name: 'Banana', entryDate: '2026-02-22T08:00:00Z'),
      _item(id: 'a', name: 'Apple', entryDate: '2026-02-20T08:00:00Z'),
      _item(id: 'c', name: 'Cherry', entryDate: '2026-02-21T08:00:00Z'),
    ], sortMode: InventoryItemSortMode.alphabeticalDescending);

    expect(ascending.map((item) => item.id), <String>['a', 'b', 'c']);
    expect(descending.map((item) => item.id), <String>['c', 'b', 'a']);
  });

  test('available amount sorts by remaining ratio', () {
    final sortedAscending = sortInventoryItems(<InventoryItem>[
      _item(
        id: 'full',
        name: 'Full',
        entryDate: '2026-02-20T08:00:00Z',
        quantity: 4,
        initialQuantity: 4,
      ),
      _item(
        id: 'half',
        name: 'Half',
        entryDate: '2026-02-21T08:00:00Z',
        quantity: 2,
        initialQuantity: 4,
      ),
      _item(
        id: 'empty',
        name: 'Empty',
        entryDate: '2026-02-22T08:00:00Z',
        quantity: 0,
        initialQuantity: 4,
      ),
    ], sortMode: InventoryItemSortMode.availableAmountAscending);
    final sortedDescending = sortInventoryItems(<InventoryItem>[
      _item(
        id: 'full',
        name: 'Full',
        entryDate: '2026-02-20T08:00:00Z',
        quantity: 4,
        initialQuantity: 4,
      ),
      _item(
        id: 'half',
        name: 'Half',
        entryDate: '2026-02-21T08:00:00Z',
        quantity: 2,
        initialQuantity: 4,
      ),
      _item(
        id: 'empty',
        name: 'Empty',
        entryDate: '2026-02-22T08:00:00Z',
        quantity: 0,
        initialQuantity: 4,
      ),
    ], sortMode: InventoryItemSortMode.availableAmountDescending);

    expect(sortedAscending.map((item) => item.id), <String>[
      'empty',
      'half',
      'full',
    ]);
    expect(sortedDescending.map((item) => item.id), <String>[
      'full',
      'half',
      'empty',
    ]);
  });
}
