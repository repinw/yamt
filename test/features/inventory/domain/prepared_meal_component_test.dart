import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

import '../../../support/prepared_meal_test_data.dart';

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

  group('nutritionFacts', () {
    test('keeps the counted energy and macros and scales the other label '
        'values to the grams the meal uses', () {
      final rice = labeledIngredientTestData(
        labeledFoodTestData(
          id: 'rice',
          name: 'Reis',
          grams: 1000,
          label: riceLabelTestData,
        ),
        200,
      );

      final facts = rice.nutritionFacts;

      expect(facts.kcal, rice.totalKcal);
      expect(facts.kcal, 700);
      expect(facts.fat, 2);
      expect(facts.carbs, 150);
      expect(facts.protein, 16);
      expect(facts.saturatedFat, 1);
      expect(facts.sugar, 2);
      expect(facts.fiber, 4);
      expect(facts.salt, 0.5);
      expect(facts.polyunsaturatedFat, isNull);
    });

    test('leaves out what the label lacks', () {
      final sauce = labeledIngredientTestData(
        labeledFoodTestData(
          id: 'sauce',
          name: 'Tomatensauce',
          grams: 500,
          label: sauceLabelTestData,
        ),
        300,
      );

      final facts = sauce.nutritionFacts;

      expect(facts.kcal, 150);
      expect(facts.fat, 6);
      expect(facts.saturatedFat, isNull);
      expect(facts.sugar, isNull);
      expect(facts.fiber, isNull);
      expect(facts.salt, isNull);
    });

    test('counts pieces as the meal totals do', () {
      final egg = _component(
        sourceItem: InventoryItem.create(
          id: 'eggs',
          name: 'Eier',
          entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
          storeName: 'Store',
          quantity: 6,
          nutrition: riceLabelTestData,
        ),
        usedAmount: 2,
      );

      expect(
        preparedMealNutritionFactor(
          item: egg.sourceItemSnapshot,
          amount: 2,
          unit: InventoryAmountUnit.piece,
        ),
        2,
      );
      expect(egg.nutritionFacts.sugar, 2);
      expect(egg.nutritionFacts.salt, 0.5);
    });

    test('has only the counted energy and macros without a label', () {
      final facts = _component(
        sourceItem: _sourceItem(amountUnit: InventoryAmountUnit.gram),
        usedAmount: 100,
        usedUnit: InventoryAmountUnit.gram,
      ).nutritionFacts;

      expect(facts.kcal, 0);
      expect(facts.sugar, isNull);
      expect(facts.salt, isNull);
    });
  });

  group('hasIncompleteNutrition', () {
    test('is false for a complete EU label, also without polyunsaturates', () {
      final rice = labeledIngredientTestData(
        labeledFoodTestData(
          id: 'rice',
          name: 'Reis',
          grams: 1000,
          label: riceLabelTestData,
        ),
        200,
      );

      expect(rice.hasIncompleteNutrition, isFalse);
    });

    test('is true when the label lacks a value such as salt', () {
      final sauce = labeledIngredientTestData(
        labeledFoodTestData(
          id: 'sauce',
          name: 'Tomatensauce',
          grams: 500,
          label: sauceLabelTestData,
        ),
        300,
      );

      expect(sauce.hasIncompleteNutrition, isTrue);
    });

    test('is true without a label', () {
      final component = _component(sourceItem: _sourceItem());

      expect(component.hasIncompleteNutrition, isTrue);
    });
  });
}
