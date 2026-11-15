import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  const builder = AiChefInventoryInputBuilder();

  test('build formats active inventory with useful prompt details', () {
    final items = [
      _inventoryItem(
        id: 'tomato',
        name: ' Tomato ',
        quantity: 2,
        weight: '500 g',
        brand: 'Garden',
        category: 'Vegetable',
      ),
      _inventoryItem(
        id: 'milk',
        name: 'Milk',
        quantity: 1,
        initialAmount: 1000,
        currentAmount: 750,
        amountUnit: InventoryAmountUnit.milliliter,
      ),
      _inventoryItem(id: 'carrot', name: 'Carrot', quantity: 3),
    ];

    final result = builder.build(items);

    expect(result, <String>[
      'Tomato (available: 2 x 500 g, brand: Garden, category: Vegetable)',
      'Milk (available: 750 ml)',
      'Carrot (available: 3 x)',
    ]);
  });

  test('build skips empty consumed and review-only items', () {
    final result = builder.build([
      _inventoryItem(id: 'blank', name: ' ', quantity: 2),
      _inventoryItem(id: 'consumed', name: 'Rice', quantity: 0),
      _inventoryItem(
        id: 'deposit',
        name: 'Deposit',
        quantity: 1,
        isDeposit: true,
      ),
      _inventoryItem(
        id: 'discount',
        name: 'Discount',
        quantity: 1,
        isDiscount: true,
      ),
      _inventoryItem(id: 'usable', name: 'Beans', quantity: 1),
    ]);

    expect(result, <String>['Beans (available: 1 x)']);
  });

  test('build limits prompt entries to forty ingredients', () {
    final items = List.generate(45, (index) {
      return _inventoryItem(
        id: 'item-$index',
        name: 'Item $index',
        quantity: 1,
      );
    });

    final result = builder.build(items);

    expect(result, hasLength(40));
    expect(result.first, 'Item 0 (available: 1 x)');
    expect(result.last, 'Item 39 (available: 1 x)');
  });

  test('pickableOldestFirst sorts the longest in stock first', () {
    final items = [
      _inventoryItem(
        id: 'new',
        name: 'Quark',
        quantity: 1,
        entryDate: DateTime(2026, 11, 10),
      ),
      _inventoryItem(
        id: 'old',
        name: 'Spinat',
        quantity: 1,
        entryDate: DateTime(2026, 11, 3),
      ),
      _inventoryItem(
        id: 'blank',
        name: ' ',
        quantity: 1,
        entryDate: DateTime(2026, 10),
      ),
    ];

    expect(builder.pickableOldestFirst(items).map((item) => item.id), [
      'old',
      'new',
    ]);
  });

  test('daysInStock counts calendar days and never goes below zero', () {
    final item = _inventoryItem(
      id: 'a',
      name: 'Spinat',
      quantity: 1,
      entryDate: DateTime(2026, 11, 3, 23, 30),
    );

    expect(builder.daysInStock(item, DateTime(2026, 11, 15, 0, 10)), 12);
    expect(builder.daysInStock(item, DateTime(2026, 11)), 0);
  });
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int quantity,
  String? weight,
  String? brand,
  String? category,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
  bool isDeposit = false,
  bool isDiscount = false,
  DateTime? entryDate,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: entryDate ?? DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: 2,
    weight: weight,
    brand: brand,
    category: category,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}
