import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_replenishment.dart';

final _now = DateTime(2026, 9, 7, 12);
InventoryItem _item(
  String id, {
  String name = 'Milk',
  String? receipt,
  String? brand = 'Farm',
  int quantity = 1,
  int initialQuantity = 1,
  int remaining = 1000,
  int initial = 1000,
  int daysAgo = 1,
  bool deposit = false,
}) => InventoryItem.create(
  id: id,
  name: name,
  brand: brand,
  entryDate: _now.subtract(Duration(days: daysAgo)),
  storeName: 'Store',
  quantity: quantity,
  initialQuantity: initialQuantity,
  initialAmount: initial,
  currentAmount: remaining,
  amountUnit: InventoryAmountUnit.milliliter,
  receiptId: receipt,
  isDeposit: deposit,
);

void main() {
  test(
    'counts distinct receipts, not duplicate rows or package quantities',
    () {
      final results = inventoryReplenishment([
        _item('1', receipt: 'a'),
        _item('2', receipt: 'a'),
        _item('3', receipt: 'b', name: ' MILK '),
      ], _now);
      expect(results.single.purchaseCount, 2);
      expect(results.single.isLowStock, isFalse);
    },
  );
  test('manual stock additions are not evidence of purchases', () {
    expect(inventoryReplenishment([_item('1'), _item('2')], _now), isEmpty);
  });
  test('low stock includes partial and depleted recent products', () {
    for (final remaining in [0, 250]) {
      expect(
        inventoryReplenishment([
          _item('1', remaining: remaining),
        ], _now).single.isLowStock,
        isTrue,
      );
    }
    expect(inventoryReplenishment([_item('1', remaining: 251)], _now), isEmpty);
  });
  test('distinguishes empty stock from a small remaining amount', () {
    final empty = inventoryReplenishment([
      _item('1', remaining: 0),
    ], _now).single;
    final low = inventoryReplenishment([
      _item('2', remaining: 100),
    ], _now).single;
    expect(empty.isOutOfStock, isTrue);
    expect(low.isOutOfStock, isFalse);
    expect(low.isLowStock, isTrue);
  });

  test('a full second batch prevents a false low-stock suggestion', () {
    expect(
      inventoryReplenishment([
        _item('1', remaining: 50),
        _item('2'),
      ], _now),
      isEmpty,
    );
  });
  test('a stocked base product covers a depleted named variant', () {
    expect(
      inventoryReplenishment([
        _item('1', name: 'Eiweißbrot - Proteinkorn', remaining: 0),
        _item('2', name: 'Eiweißbrot'),
      ], _now),
      isEmpty,
    );
  });
  test('a matching stocked variant removes the out-of-stock reason', () {
    final result = inventoryReplenishment([
      _item(
        '1',
        name: 'Eiweißbrot - Proteinkorn',
        receipt: 'a',
        remaining: 0,
      ),
      _item('2', name: 'EIWEISSBROT', receipt: 'b', daysAgo: 2),
    ], _now).single;
    expect(result.purchaseCount, 2);
    expect(result.isLowStock, isFalse);
    expect(result.isOutOfStock, isFalse);
  });
  test('aggregates pack equivalents across different pack sizes', () {
    expect(
      inventoryReplenishment([
        _item('1', initial: 500, remaining: 100),
        _item('2', initial: 2000, remaining: 200),
      ], _now),
      isEmpty,
    );
  });
  test('a multi-pack uses all original packages for remaining pack count', () {
    expect(
      inventoryReplenishment([
        _item('1', initial: 4000, remaining: 500, initialQuantity: 4),
      ], _now),
      isEmpty,
    );
  });
  test(
    'keeps brands distinct and excludes deposits, future and stale history',
    () {
      expect(
        inventoryReplenishment([
          _item('1', receipt: 'a'),
          _item('2', receipt: 'b', brand: 'Other'),
          _item('3', receipt: 'c', daysAgo: 181),
          _item('4', receipt: 'd', daysAgo: -1),
          _item('5', receipt: 'e', remaining: 0, deposit: true),
        ], _now),
        isEmpty,
      );
      expect(
        inventoryReplenishment([_item('6', remaining: 0, daysAgo: 61)], _now),
        isEmpty,
      );
    },
  );
  test('prioritizes low stock before purchase frequency', () {
    final results = inventoryReplenishment([
      _item('1', receipt: 'a'),
      _item('2', receipt: 'b'),
      _item('3', name: 'Bread', remaining: 100),
    ], _now);
    expect(results.map((item) => item.name), ['Bread', 'Milk']);
  });
}
