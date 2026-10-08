import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

InventoryItem _sourceItem({
  String id = 'item-1',
  String name = 'Rice',
  int quantity = 1,
  int initialQuantity = 1,
  double unitPrice = 1.0,
  int initialAmount = 0,
  int currentAmount = 0,
  int amountScale = 1,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: unitPrice,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountScale: amountScale,
    amountUnit: amountUnit,
  );
}

PreparedMealComponent _component({
  required InventoryItem sourceItem,
  int usedAmount = 1,
  InventoryAmountUnit usedUnit = InventoryAmountUnit.piece,
}) {
  return PreparedMealComponent(
    inventoryItemId: sourceItem.id,
    name: sourceItem.name,
    brand: sourceItem.brand,
    imageUrl: sourceItem.imageUrl,
    usedAmount: usedAmount,
    usedUnit: usedUnit,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    sourceItemSnapshot: sourceItem,
  );
}

class _AlwaysAmountProgressInventoryItem extends InventoryItem {
  new({
    required super.id,
    required String name,
    required super.entryDate,
    required super.storeName,
    required super.quantity,
    super.unitPrice = 0.0,
    super.amountUnit,
  }) : super(
         globalFoodItemId: 'pending-$id',
         productSnapshot: InventoryItemProductSnapshot(name: name),
         initialQuantity: 1,
       );

  @override
  bool get usesAmountProgress => true;
}

void main() {
  test(
    'PreparedMealComponent totals price by piece count for piece-based items',
    () {
      final sourceItem = InventoryItem.create(
        id: 'item-1',
        name: 'Egg',
        entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
        storeName: 'Store',
        quantity: 6,
        initialQuantity: 6,
        unitPrice: 0.4,
      );
      final component = PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 3,
        usedUnit: InventoryAmountUnit.piece,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        sourceItemSnapshot: sourceItem,
      );

      expect(component.totalPrice, closeTo(1.2, 0.0001));
    },
  );

  test(
    'PreparedMealComponent totalPrice returns zero for non-positive usage',
    () {
      final component = _component(
        sourceItem: _sourceItem(unitPrice: 2.5),
        usedAmount: 0,
      );

      expect(component.totalPrice, 0);
    },
  );

  test(
    'PreparedMealComponent totalPrice returns zero without initial amount',
    () {
      final sourceItem = _AlwaysAmountProgressInventoryItem(
        id: 'item-1',
        name: 'Rice',
        entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
        storeName: 'Store',
        quantity: 1,
        unitPrice: 2.5,
        amountUnit: InventoryAmountUnit.gram,
      );
      final component = _component(
        sourceItem: sourceItem,
        usedAmount: 100,
        usedUnit: InventoryAmountUnit.gram,
      );

      expect(component.totalPrice, 0);
    },
  );

  group('preparedMealComponentDisplayAmount', () {
    test('divides a fractional-piece amount by the source item scale', () {
      final component = _component(
        sourceItem: _sourceItem(
          amountUnit: InventoryAmountUnit.piece,
          amountScale: inventoryPieceAmountScale,
        ),
        usedAmount: 8000,
      );

      expect(component.usedAmountScale, inventoryPieceAmountScale);
      expect(preparedMealComponentDisplayAmount(component), 8);
    });

    test('leaves a gram amount unscaled', () {
      final component = _component(
        sourceItem: _sourceItem(amountUnit: InventoryAmountUnit.gram),
        usedAmount: 150,
        usedUnit: InventoryAmountUnit.gram,
      );

      expect(component.usedAmountScale, 1);
      expect(preparedMealComponentDisplayAmount(component), 150);
    });

    test('keeps fractional precision for a scaled raw gram amount', () {
      final component = _component(
        sourceItem: _sourceItem(amountUnit: InventoryAmountUnit.gram),
        usedAmount: 200,
        usedUnit: InventoryAmountUnit.gram,
      );

      expect(
        preparedMealComponentDisplayAmount(component, 200 / 3),
        closeTo(66.6667, 0.0001),
      );
    });

    test('scales a fractional-piece raw amount by portion ratio', () {
      final component = _component(
        sourceItem: _sourceItem(
          amountUnit: InventoryAmountUnit.piece,
          amountScale: inventoryPieceAmountScale,
        ),
        usedAmount: 8000,
      );

      expect(preparedMealComponentDisplayAmount(component, 8000 * 0.5), 4);
    });
  });
}
