import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

InventoryItem _item({DateTime? lastConsumedAt, int quantity = 2}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: 1,
    lastConsumedAt: lastConsumedAt,
  );
}

InventoryItem _amountItem({
  required int quantity,
  required int initialQuantity,
  required int initialAmount,
  required int currentAmount,
}) {
  return InventoryItem.create(
    id: 'item-2',
    name: 'Juice',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

void main() {
  test('latestConsumedAtOr returns candidate when no timestamp exists', () {
    final item = _item();
    final candidate = DateTime.parse('2026-02-20T12:00:00Z');

    expect(item.latestConsumedAtOr(candidate), candidate);
  });

  test('latestConsumedAtOr keeps newer current timestamp', () {
    final current = DateTime.parse('2026-02-21T12:00:00Z');
    final olderCandidate = DateTime.parse('2026-02-20T12:00:00Z');
    final item = _item(lastConsumedAt: current);

    expect(item.latestConsumedAtOr(olderCandidate), current);
  });

  test('latestConsumedAtOr accepts a newer candidate timestamp', () {
    final current = DateTime.parse('2026-02-20T12:00:00Z');
    final newerCandidate = DateTime.parse('2026-02-21T12:00:00Z');
    final item = _item(lastConsumedAt: current);

    expect(item.latestConsumedAtOr(newerCandidate), newerCandidate);
  });

  test('consumable amount guards invalid items', () {
    final stockedQuantityItem = InventoryItem.create(
      id: 'item-stocked',
      name: 'Yogurt',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 3,
    );
    final stockedAmountItem = InventoryItem.create(
      id: 'item-amount',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 750,
      amountUnit: InventoryAmountUnit.milliliter,
    );
    final quantitylessItem = InventoryItem.create(
      id: 'item-0',
      name: 'Nothing',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 0,
    );
    final depletedAmountItem = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 1000,
      amountUnit: InventoryAmountUnit.milliliter,
    );

    expect(consumableInventoryAmount(stockedQuantityItem), 3);
    expect(consumableInventoryAmount(stockedAmountItem), 750);
    expect(consumableInventoryAmount(quantitylessItem), isNull);
    expect(consumableInventoryAmount(depletedAmountItem), isNull);
  });

  group('availableAmount', () {
    test('counts quantity, or current amount for amount items', () {
      expect(_item(quantity: 3).availableAmount, 3);
      expect(
        _amountItem(
          quantity: 1,
          initialQuantity: 1,
          initialAmount: 1000,
          currentAmount: 750,
        ).availableAmount,
        750,
      );
    });

    test('never goes below zero', () {
      expect(_item(quantity: -2).availableAmount, 0);
      expect(
        _amountItem(
          quantity: 1,
          initialQuantity: 1,
          initialAmount: 1000,
          currentAmount: -5,
        ).availableAmount,
        0,
      );
    });
  });

  group('quantityForAmount', () {
    test('rounds the package share up', () {
      final item = _amountItem(
        quantity: 3,
        initialQuantity: 3,
        initialAmount: 1000,
        currentAmount: 1000,
      );

      expect(item.quantityForAmount(499), 2);
      expect(item.quantityForAmount(0), 0);
    });

    test('caps the quantity at the initial quantity', () {
      final item = _amountItem(
        quantity: 3,
        initialQuantity: 3,
        initialAmount: 1000,
        currentAmount: 1200,
      );

      expect(item.quantityForAmount(1190), 3);
    });

    test('keeps the quantity without an initial amount or quantity', () {
      final noInitialAmount = _amountItem(
        quantity: 7,
        initialQuantity: 7,
        initialAmount: 0,
        currentAmount: 0,
      );
      final noInitialQuantity = _amountItem(
        quantity: 7,
        initialQuantity: 0,
        initialAmount: 1000,
        currentAmount: 0,
      );

      expect(noInitialAmount.quantityForAmount(500), 7);
      expect(noInitialQuantity.quantityForAmount(500), 7);
    });
  });

  group('reducedBy', () {
    final consumedAt = DateTime.parse('2026-02-20T12:00:00Z');

    test('takes quantity and moves lastConsumedAt forward', () {
      final reduced = _item(quantity: 5).reducedBy(2, consumedAt: consumedAt);

      expect(reduced?.quantity, 3);
      expect(reduced?.lastConsumedAt, consumedAt);
    });

    test('takes current amount and recomputes the quantity', () {
      final reduced = _amountItem(
        quantity: 2,
        initialQuantity: 2,
        initialAmount: 1000,
        currentAmount: 600,
      ).reducedBy(200);

      expect(reduced?.currentAmount, 400);
      expect(reduced?.quantity, 1);
    });

    test('takes all that is left', () {
      final reduced = _amountItem(
        quantity: 1,
        initialQuantity: 1,
        initialAmount: 1000,
        currentAmount: 50,
      ).reducedBy(50);

      expect(reduced?.currentAmount, 0);
      expect(reduced?.quantity, 0);
    });

    test('rejects an amount above the available stock', () {
      expect(_item(quantity: 3).reducedBy(4), isNull);
      expect(
        _amountItem(
          quantity: 1,
          initialQuantity: 1,
          initialAmount: 1000,
          currentAmount: 50,
        ).reducedBy(51),
        isNull,
      );
    });

    test('rejects amounts below one', () {
      expect(_item().reducedBy(0), isNull);
      expect(_item().reducedBy(-1), isNull);
    });

    test('keeps lastConsumedAt without consumedAt', () {
      final current = DateTime.parse('2026-02-19T12:00:00Z');

      final reduced = _item(lastConsumedAt: current).reducedBy(1);

      expect(reduced?.lastConsumedAt, current);
    });

    test('keeps a newer lastConsumedAt than consumedAt', () {
      final current = DateTime.parse('2026-02-21T12:00:00Z');

      final reduced = _item(lastConsumedAt: current)
          .reducedBy(1, consumedAt: consumedAt);

      expect(reduced?.lastConsumedAt, current);
    });
  });
}
