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
}
