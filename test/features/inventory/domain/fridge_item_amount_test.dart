import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item({
  String? weight,
  int quantity = 1,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: 1.99,
    weight: weight,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
  );
}

void main() {
  test('withDerivedAmount parses grams into base unit', () {
    final item = _item(weight: '300g').withDerivedAmount();

    expect(item.initialAmount, 300);
    expect(item.currentAmount, 300);
    expect(item.amountUnit, InventoryAmountUnit.gram);
  });

  test('withDerivedAmount converts liters to milliliters', () {
    final item = _item(weight: '1l', quantity: 2).withDerivedAmount();

    expect(item.initialAmount, 2000);
    expect(item.currentAmount, 2000);
    expect(item.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('withDerivedAmount supports multipack notation', () {
    final item = _item(weight: '20x0.33l', quantity: 2).withDerivedAmount();

    expect(item.initialAmount, 13200);
    expect(item.currentAmount, 13200);
    expect(item.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('withDerivedAmount converts kilograms to grams', () {
    final item = _item(weight: '0.25kg').withDerivedAmount();

    expect(item.initialAmount, 250);
    expect(item.currentAmount, 250);
    expect(item.amountUnit, InventoryAmountUnit.gram);
  });

  test('withDerivedAmount can use fallback enum unit', () {
    final item = _item(
      weight: '300',
    ).withDerivedAmount(fallbackUnit: InventoryAmountUnit.gram);

    expect(item.initialAmount, 300);
    expect(item.currentAmount, 300);
    expect(item.amountUnit, InventoryAmountUnit.gram);
  });

  test('withDerivedAmount uses fallback enum for unknown suffix', () {
    final item = _item(
      weight: '300abc',
    ).withDerivedAmount(fallbackUnit: InventoryAmountUnit.gram);

    expect(item.initialAmount, 300);
    expect(item.currentAmount, 300);
    expect(item.amountUnit, InventoryAmountUnit.gram);
  });
}
