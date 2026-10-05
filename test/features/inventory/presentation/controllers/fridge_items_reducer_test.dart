import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';

InventoryItem _item({required String id, required int quantity}) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: 1,
  );
}

final DateTime _consumedAt = DateTime.parse('2026-02-20T12:00:00Z');

void main() {
  test('buildReducedItems reduces quantity by a valid amount', () {
    final originalItems = <InventoryItem>[_item(id: 'a', quantity: 5)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 2,
      consumedAt: _consumedAt,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems, hasLength(1));
    expect(reducedItems?.single.quantity, 3);
    expect(reducedItems?.single.lastConsumedAt, _consumedAt);
    expect(originalItems.single.quantity, 5);
  });

  test('buildReducedItems clips amount above max reducible to zero stock', () {
    final originalItems = <InventoryItem>[_item(id: 'a', quantity: 3)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 99,
      consumedAt: _consumedAt,
    );

    expect(reducedItems, isNotNull);
    expect(reducedItems?.single.quantity, 0);
    expect(originalItems.single.quantity, 3);
  });

  test('buildReducedItems clips an amount item to zero stock', () {
    final originalItems = <InventoryItem>[
      InventoryItem.create(
        id: 'a',
        name: 'Juice',
        entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
        storeName: 'Store',
        quantity: 1,
        unitPrice: 1,
        initialAmount: 1000,
        currentAmount: 50,
        amountUnit: InventoryAmountUnit.milliliter,
      ),
    ];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'a',
      amount: 200,
      consumedAt: _consumedAt,
    );

    expect(reducedItems?.single.currentAmount, 0);
    expect(reducedItems?.single.quantity, 0);
  });

  test('buildReducedItems returns null when item is missing', () {
    final originalItems = <InventoryItem>[_item(id: 'a', quantity: 3)];

    final reducedItems = buildReducedItems(
      currentItems: originalItems,
      itemId: 'missing',
      amount: 1,
      consumedAt: _consumedAt,
    );

    expect(reducedItems, isNull);
  });

  test('buildReducedItems returns null for non-positive amounts', () {
    final originalItems = <InventoryItem>[_item(id: 'a', quantity: 3)];

    for (final invalidAmount in <int>[0, -1]) {
      final reducedItems = buildReducedItems(
        currentItems: originalItems,
        itemId: 'a',
        amount: invalidAmount,
        consumedAt: _consumedAt,
      );
      expect(reducedItems, isNull);
    }

    expect(originalItems.single.quantity, 3);
  });
}
