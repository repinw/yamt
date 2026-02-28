import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';

FridgeItem _item({required String id, required int quantity}) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: 1.0,
  );
}

FridgeItem _amountItem({
  required String id,
  required int quantity,
  required int initialQuantity,
  required int initialAmount,
  required int currentAmount,
}) {
  return FridgeItem(
    id: id,
    name: 'Juice',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1.0,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: FridgeAmountUnit.milliliter,
  );
}

void main() {
  test('buildReducedItems reduces quantity by a valid amount', () {
    final originalItems = <FridgeItem>[_item(id: 'a', quantity: 5)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 2,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems, hasLength(1));
    expect(reducedItems?.single.quantity, 3);
    expect(originalItems.single.quantity, 5);
  });

  test('buildReducedItems clips amount above max reducible to zero stock', () {
    final originalItems = <FridgeItem>[_item(id: 'a', quantity: 3)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 99,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.quantity, 0);
    expect(originalItems.single.quantity, 3);
  });

  test('buildReducedItems returns null when item is missing', () {
    final originalItems = <FridgeItem>[_item(id: 'a', quantity: 3)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'missing',
      amount: 1,
    );

    expect(reducedItems, isNull);
  });

  test('buildReducedItems returns null for non-positive amounts', () {
    final originalItems = <FridgeItem>[_item(id: 'a', quantity: 3)];

    for (final invalidAmount in <int>[0, -1]) {
      final reducedItems = buildReducedItems(
        currentItems: originalItems,
        itemId: 'a',
        amount: invalidAmount,
      );
      expect(reducedItems, isNull);
    }

    expect(originalItems.single.quantity, 3);
  });

  test('buildReducedItems reduces currentAmount for amount-based item', () {
    final originalItems = <FridgeItem>[
      _amountItem(
        id: 'a',
        quantity: 2,
        initialQuantity: 2,
        initialAmount: 1000,
        currentAmount: 600,
      ),
    ];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 200,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.currentAmount, 400);
    expect(reducedItems?.single.quantity, 1);
    expect(originalItems.single.currentAmount, 600);
  });

  test('buildReducedItems recalculates quantity with ceil ratio', () {
    final originalItems = <FridgeItem>[
      _amountItem(
        id: 'a',
        quantity: 3,
        initialQuantity: 3,
        initialAmount: 1000,
        currentAmount: 500,
      ),
    ];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 1,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.currentAmount, 499);
    expect(reducedItems?.single.quantity, 2);
  });

  test('buildReducedItems clamps amount-based currentAmount to zero', () {
    final originalItems = <FridgeItem>[
      _amountItem(
        id: 'a',
        quantity: 1,
        initialQuantity: 1,
        initialAmount: 1000,
        currentAmount: 50,
      ),
    ];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 200,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.currentAmount, 0);
    expect(reducedItems?.single.quantity, 0);
  });

  test(
    'buildReducedItems keeps quantity when initialQuantity is below one',
    () {
      final originalItems = <FridgeItem>[
        _amountItem(
          id: 'a',
          quantity: 7,
          initialQuantity: 0,
          initialAmount: 1000,
          currentAmount: 800,
        ),
      ];

      final reducedItems = buildReducedItems(
        currentItems: originalItems,
        itemId: 'a',
        amount: 100,
      );

      expect(reducedItems, isNotNull);
      expect(reducedItems?.single.currentAmount, 700);
      expect(reducedItems?.single.quantity, 7);
    },
  );

  test('buildReducedItems caps projected quantity at initialQuantity', () {
    final originalItems = <FridgeItem>[
      _amountItem(
        id: 'a',
        quantity: 3,
        initialQuantity: 3,
        initialAmount: 1000,
        currentAmount: 1200,
      ),
    ];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 10,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.currentAmount, 1190);
    expect(reducedItems?.single.quantity, 3);
  });

  test(
    'quantityForCurrentAmount falls back when initialAmount is below one',
    () {
      final item = _amountItem(
        id: 'a',
        quantity: 7,
        initialQuantity: 7,
        initialAmount: 0,
        currentAmount: 0,
      );

      final quantity = quantityForCurrentAmount(item: item, currentAmount: 500);

      expect(quantity, 7);
    },
  );

  test(
    'quantityForCurrentAmount falls back when initialQuantity is below one',
    () {
      final item = _amountItem(
        id: 'a',
        quantity: 7,
        initialQuantity: 0,
        initialAmount: 1000,
        currentAmount: 0,
      );

      final quantity = quantityForCurrentAmount(item: item, currentAmount: 500);

      expect(quantity, 7);
    },
  );
}
