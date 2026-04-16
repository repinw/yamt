import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_progress.dart';

InventoryItem _item({
  int initialQuantity = 1,
  int quantity = 1,
  String? weight,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1,
    weight: weight,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
  );
}

void main() {
  const calculator = InventoryItemProgressCalculator();

  test('uses amount-based progress when amount data is available', () {
    final item = _item(
      initialQuantity: 4,
      quantity: 3,
      weight: '500g',
      initialAmount: 1000,
      currentAmount: 250,
      amountUnit: InventoryAmountUnit.gram,
    );

    final progress = calculator.fromItem(item);

    expect(progress.remainingRatio, closeTo(0.25, 0.0001));
    expect(progress.remainingLabel, '250g / 1000g');
    expect(progress.segmentedByUnits, isTrue);
    expect(progress.totalUnits, 4);
    expect(progress.remainingUnits, 3);
  });

  test('clamps amount-based progress to valid bounds', () {
    final item = _item(
      initialQuantity: 5,
      quantity: 9,
      initialAmount: 1000,
      currentAmount: 3000,
      amountUnit: InventoryAmountUnit.milliliter,
    );

    final progress = calculator.fromItem(item);

    expect(progress.remainingRatio, 1.0);
    expect(progress.remainingLabel, '1000ml / 1000ml');
    expect(progress.segmentedByUnits, isTrue);
    expect(progress.totalUnits, 5);
    expect(progress.remainingUnits, 5);
  });

  test('falls back to quantity progress and segments for multi-unit items', () {
    final item = _item(
      initialQuantity: 4,
      quantity: 3,
    );

    final progress = calculator.fromItem(item);

    expect(progress.remainingRatio, closeTo(0.75, 0.0001));
    expect(progress.remainingLabel, '3/4');
    expect(progress.segmentedByUnits, isTrue);
    expect(progress.totalUnits, 4);
    expect(progress.remainingUnits, 3);
  });

  test('does not segment quantity progress when total units is one', () {
    final item = _item();

    final progress = calculator.fromItem(item);

    expect(progress.remainingRatio, 1.0);
    expect(progress.remainingLabel, '1/1');
    expect(progress.segmentedByUnits, isFalse);
    expect(progress.totalUnits, 1);
    expect(progress.remainingUnits, 1);
  });

  test('quantity progress clamps invalid values safely', () {
    final item = _item(initialQuantity: 0, quantity: -2);

    final progress = calculator.fromItem(item);

    expect(progress.remainingRatio, 0.0);
    expect(progress.remainingLabel, '0/1');
    expect(progress.segmentedByUnits, isFalse);
    expect(progress.totalUnits, 1);
    expect(progress.remainingUnits, 0);
  });
}
