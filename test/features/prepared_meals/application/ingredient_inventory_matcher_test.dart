import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  int quantity = 1,
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

List<InventoryItem> _match({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  String? localeCode,
}) => [
  for (final (:item, score: _) in scoreInventoryItemsForIngredient(
    ingredient: ingredient,
    inventoryItems: inventoryItems,
    localeCode: localeCode,
  ))
    item,
];

void main() {
  test('scoreInventoryItemsForIngredient sorts best matches first', () {
    final inventoryItems = <InventoryItem>[
      _item(id: '1', name: 'Kartoffeln'),
      _item(id: '2', name: 'Bio Kartoffeln'),
      _item(id: '3', name: 'Milch'),
      _item(id: '4', name: 'Kartoffeln', quantity: 0),
    ];

    final matches = _match(
      ingredient: 'Kartoffeln',
      inventoryItems: inventoryItems,
    );

    expect(matches.map((item) => item.id), <String>['1', '2']);
  });

  test('prefers exact matches over broader partial matches', () {
    final matches = _match(
      ingredient: 'Milch',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Hafermilch'),
        _item(id: '2', name: 'Milch'),
      ],
    );

    expect(matches.map((item) => item.id), <String>['2', '1']);
  });

  test('matches german carrot synonyms with quantities', () {
    final matches = _match(
      ingredient: '2 Möhren',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Karotten'),
        _item(id: '2', name: 'Milch'),
      ],
      localeCode: 'de',
    );

    expect(matches.map((item) => item.id), <String>['1']);
  });

  test('matches english scallion synonyms with english lexicon', () {
    final matches = _match(
      ingredient: '2 spring onions',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Scallions'),
        _item(id: '2', name: 'Milk'),
      ],
      localeCode: 'en',
    );

    expect(matches.map((item) => item.id), <String>['1']);
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

  test('the matcher ignores common english filler words', () {
    final rankedItems = _match(
      ingredient: 'fresh large milk',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Fresh Large'),
        _item(id: '2', name: 'Milk'),
      ],
      localeCode: 'en',
    );

    expect(rankedItems.map((item) => item.id).first, '2');
  });

  test('the matcher uses fuzzy score for noisy imports', () {
    final rankedItems = _match(
      ingredient: 'mittelgroße Zwiebeln',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Mittelgroße Vorratsdose'),
        _item(id: '2', name: 'Zwiebeln'),
      ],
      localeCode: 'de',
    );

    expect(rankedItems.map((item) => item.id).first, '2');
  });

  test('the matcher matches compounds by character shingles', () {
    final rankedItems = _match(
      ingredient: 'Rinderhackfleisch',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Bio-Speisezwiebeln'),
        _item(id: '2', name: 'Schwin Schweine Hack'),
      ],
      localeCode: 'de',
    );

    expect(rankedItems.map((item) => item.id).first, '2');
  });

  test('the matcher still matches onion compounds', () {
    final rankedItems = _match(
      ingredient: 'Zwiebeln',
      inventoryItems: <InventoryItem>[
        _item(id: '1', name: 'Bio-Speisezwiebeln'),
        _item(id: '2', name: 'Schwin Schweine Hack'),
      ],
      localeCode: 'de',
    );

    expect(rankedItems.map((item) => item.id).first, '1');
  });

  test('scoreInventoryItemsForIngredient returns empty for blank input', () {
    final matches = _match(
      ingredient: '   ',
      inventoryItems: <InventoryItem>[_item(id: '1', name: 'Milch')],
    );

    expect(matches, isEmpty);
  });

  test(
    'scoreInventoryItemsForIngredient returns empty for symbols only input',
    () {
      final matches = _match(
        ingredient: '!@#',
        inventoryItems: <InventoryItem>[_item(id: '1', name: 'Milch')],
      );

      expect(matches, isEmpty);
    },
  );

  test('hasInventoryItemForIngredient answers like a non-empty match list', () {
    final inventoryItems = <InventoryItem>[
      _item(id: '1', name: 'Kartoffeln'),
      _item(id: '2', name: 'Bio Hafermilch', brand: 'Oatly'),
      _item(id: '3', name: 'Karotten'),
      _item(id: '4', name: 'Frühlingszwiebeln'),
      _item(id: '5', name: 'Rote Zwiebeln'),
      _item(id: '6', name: 'Parmesan', quantity: 0),
      _item(id: '7', name: 'Spaghetti No. 5', brand: 'Barilla'),
    ];
    const ingredients = <String>[
      'Kartoffeln',
      '500 g Kartoffeln',
      'Milch',
      '2 Möhren',
      'Lauchzwiebeln',
      'scallions',
      'Zwiebel',
      'Parmesan',
      'Spaghetti',
      'Reis',
      'Olivenöl',
      '',
      '   ',
    ];

    for (final localeCode in <String?>[null, 'de', 'en']) {
      for (final ingredient in ingredients) {
        expect(
          hasInventoryItemForIngredient(
            ingredient: ingredient,
            inventoryItems: inventoryItems,
            localeCode: localeCode,
          ),
          _match(
            ingredient: ingredient,
            inventoryItems: inventoryItems,
            localeCode: localeCode,
          ).isNotEmpty,
          reason: '$localeCode: "$ingredient"',
        );
      }
    }
    expect(
      hasInventoryItemForIngredient(
        ingredient: 'Kartoffeln',
        inventoryItems: inventoryItems,
      ),
      isTrue,
    );
    expect(
      hasInventoryItemForIngredient(
        ingredient: 'Parmesan',
        inventoryItems: inventoryItems,
      ),
      isFalse,
    );
  });

  test('a compound written as two words matches the item written as one, '
      'and the other way round, but joins no words into other foods', () {
    List<String> ids(String ingredient, List<InventoryItem> items) => [
      for (final item in _match(
        ingredient: ingredient,
        inventoryItems: items,
        localeCode: 'de',
      ))
        item.id,
    ];

    expect(
      ids('100 g Test Reis', [
        _item(id: 'long-grain', name: 'Langkornreis', brand: 'Reis-Fit'),
        _item(id: 'test-rice', name: 'Testreis'),
      ]).first,
      'test-rice',
    );
    expect(
      ids('1 Dose Kidneybohnen', [
        _item(id: 'beans', name: 'Bohnen'),
        _item(id: 'kidney', name: 'Kidney Bohnen'),
      ]).first,
      'kidney',
    );
    // With brands, the exact spelling still comes first.
    expect(
      ids('1 Dose Kidney Bohnen', [
        _item(id: 'compact', name: 'Kidneybohnen', brand: 'Rewe'),
        _item(id: 'spaced', name: 'Kidney Bohnen', brand: 'Edeka'),
      ]).first,
      'spaced',
    );
    // "heringintomatensoße" holds "gin", "rotelinsen" holds no "rotwein".
    expect(
      ids('200 g Hering in Tomatensoße', [
        _item(id: 'gin', name: 'Gin'),
        _item(id: 'herring', name: 'Heringsfilet'),
      ]),
      ['herring'],
    );
    expect(
      ids('200 g Rote Linsen', [_item(id: 'wine', name: 'Rotwein')]),
      isEmpty,
    );
  });
}
