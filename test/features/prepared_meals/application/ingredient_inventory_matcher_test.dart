import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/prepared_meals/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/prepared_meals/domain/inventory_item.dart';

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  var quantity = 1,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    brand: brand,
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
  );
}

void main() {
  test('matchInventoryItemsForIngredient sorts best matches first', () {
    final inventoryItems = <InventoryItem>[
      _item(id: '1', name: 'Kartoffeln'),
      _item(id: '2', name: 'Bio Kartoffeln'),
      _item(id: '3', name: 'Milch'),
      _item(id: '4', name: 'Kartoffeln', quantity: 0),
    ];

    final matches = matchInventoryItemsForIngredient(
      ingredient: 'Kartoffeln',
      inventoryItems: inventoryItems,
    );

    expect(matches.map((item) => item.id), <String>['1', '2']);
  });

  test('rankInventoryItemsForIngredient keeps non matches for manual pick', () {
    final inventoryItems = <InventoryItem>[
      _item(id: '1', name: 'Milch'),
      _item(id: '2', name: 'Kartoffeln'),
      _item(id: '3', name: 'Joghurt'),
      _item(id: '4', name: 'Kartoffeln', quantity: 0),
    ];

    final rankedItems = rankInventoryItemsForIngredient(
      ingredient: 'Kartoffeln',
      inventoryItems: inventoryItems,
    );

    expect(rankedItems.map((item) => item.id), <String>['2', '3', '1']);
  });

  test('resolveInventoryItemsById returns only existing items', () {
    final inventoryItems = <InventoryItem>[
      _item(id: '1', name: 'Kartoffeln'),
      _item(id: '2', name: 'Milch'),
    ];

    final resolvedItems = resolveInventoryItemsById(
      inventoryItemIds: const <String>['2', 'missing', '1'],
      inventoryItems: inventoryItems,
    );

    expect(resolvedItems.map((item) => item.id), <String>['2', '1']);
  });

  test(
    'rankInventoryItemsForIngredient ignores common english filler words',
    () {
      final rankedItems = rankInventoryItemsForIngredient(
        ingredient: 'fresh large milk',
        inventoryItems: <InventoryItem>[
          _item(id: '1', name: 'Fresh Large'),
          _item(id: '2', name: 'Milk'),
        ],
      );

      expect(rankedItems.map((item) => item.id).first, '2');
    },
  );
}
