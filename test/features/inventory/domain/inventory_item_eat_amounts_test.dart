import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_amounts.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';

/// Two eggs whose stock keeps parts of an egg, with 1.25 left.
InventoryItemEatCalculator _eggs() {
  return InventoryItemEatCalculator(
    item: InventoryItem.create(
      id: 'eggs',
      name: 'Egg',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Store',
      quantity: 2,
      initialQuantity: 2,
      initialAmount: 2000,
      currentAmount: 1250,
      amountScale: inventoryPieceAmountScale,
      amountUnit: InventoryAmountUnit.piece,
    ),
    maxAmount: 1250,
  );
}

/// Cheese with 200 g left, sold in 250 g packages.
InventoryItemEatCalculator _cheese({int? packageAmount}) {
  return InventoryItemEatCalculator(
    item: InventoryItem.create(
      id: 'cheese',
      name: 'Cheese',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 250,
      currentAmount: 200,
      amountUnit: InventoryAmountUnit.gram,
      weight: '250 g',
    ),
    maxAmount: 200,
    packageAmount: packageAmount,
  );
}

void main() {
  test('pieces become stock units, never more than is left', () {
    final eggs = _eggs();

    expect(eggs.stockAmountOfPieces(1), 1000);
    expect(eggs.stockAmountOfPieces(0.5), 500);
    expect(eggs.stockAmountOfPieces(2), 1250);
    expect(eggs.maxPieces, 1.25);
  });

  test('the wheel holds the portions of a weight the stock has', () {
    final cheese = _cheese();

    expect(cheese.maxPortionsOf(40), 5);
    expect(cheese.maxPortionsOf(0), 1);
  });

  test('the ruler snaps to half portions within the stock', () {
    final cheese = _cheese();

    expect(cheese.halfPortionAmount(33, 40), 40);
    expect(cheese.halfPortionAmount(5, 40), 20);
    expect(cheese.halfPortionAmount(500, 40), 200);
  });

  test('a portion over twice the stock leaves the ruler amount free', () {
    final cheese = _cheese();

    // No half of 500 g fits into the 200 g left.
    expect(cheese.halfPortionAmount(150, 500), 150);
    expect(cheese.halfPortionAmount(300, 500), 200);
  });

  test('portion steps go to the next whole portion', () {
    final cheese = _cheese();

    expect(cheese.steppedPortionAmount(50, 40, up: true), 80);
    expect(cheese.steppedPortionAmount(80, 40, up: true), 120);
    expect(cheese.steppedPortionAmount(50, 40, up: false), 40);
    expect(cheese.steppedPortionAmount(30, 40, up: false), 0);
    expect(cheese.steppedPortionAmount(200, 40, up: true), isNull);
  });

  test('package steps go to the next whole package', () {
    expect(_cheese().steppedPackageAmount(50, up: true), isNull);

    final cheese = _cheese(packageAmount: 100);
    expect(cheese.steppedPackageAmount(50, up: true), 100);
    expect(cheese.steppedPackageAmount(100, up: true), 200);
    expect(cheese.steppedPackageAmount(150, up: false), 100);
    expect(cheese.steppedPackageAmount(50, up: false), 0);
    expect(cheese.packageCountOf(199.9995), 2);
    expect(cheese.packageCountOf(150), 1);
    expect(_cheese().packageCountOf(150), isNull);
  });

  test('the package size falls back to the product weight', () {
    expect(_cheese().packageSize, 250);
    expect(_cheese(packageAmount: 100).packageSize, 100);
    expect(_eggs().packageSize, isNull);
  });

  test('a count gives the amount within one-decimal rounding', () {
    expect(portionCountGivesAmount(count: 2, portion: 40, amount: 80), true);
    expect(
      portionCountGivesAmount(count: 3, portion: 33.33, amount: 100),
      true,
    );
    expect(portionCountGivesAmount(count: 2, portion: 40, amount: 81), false);
    expect(portionCountGivesAmount(count: 2, portion: 40, amount: 0), true);
  });
}
