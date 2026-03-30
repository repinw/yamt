import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

InventoryItem _sourceItem({
  String id = 'item-1',
  String name = 'Rice',
  int quantity = 1,
  int initialQuantity = 1,
  double unitPrice = 1.0,
  int initialAmount = 0,
  int currentAmount = 0,
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

PreparedMeal _meal({
  List<PreparedMealComponent> components = const <PreparedMealComponent>[],
}) {
  return PreparedMeal(
    id: 'meal-1',
    name: 'Meal',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: components,
  );
}

class _AlwaysAmountProgressInventoryItem extends InventoryItem {
  _AlwaysAmountProgressInventoryItem({
    required String id,
    required String name,
    required DateTime entryDate,
    required String storeName,
    required int quantity,
    int initialQuantity = 1,
    double unitPrice = 0.0,
    int initialAmount = 0,
    int currentAmount = 0,
    InventoryAmountUnit? amountUnit,
  }) : super(
         id: id,
         globalFoodItemId: 'pending-$id',
         productSnapshot: InventoryItemProductSnapshot(name: name),
         entryDate: entryDate,
         storeName: storeName,
         quantity: quantity,
         initialQuantity: initialQuantity,
         unitPrice: unitPrice,
         initialAmount: initialAmount,
         currentAmount: currentAmount,
         amountUnit: amountUnit,
       );

  @override
  bool get usesAmountProgress => true;
}

void main() {
  test('PreparedMeal JSON roundtrip keeps nested component snapshot', () {
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Rice',
      entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      initialQuantity: 1,
      initialAmount: 500,
      currentAmount: 350,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 360,
        per100Protein: 7,
        per100Carbs: 79,
        per100Fat: 1,
      ),
    );
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Rice bowl',
      imageAssetId: 'asset-1',
      totalPortions: 4,
      remainingPortions: 3,
      totalKcal: 720,
      totalProtein: 14,
      totalCarbs: 158,
      totalFat: 2,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:05:00Z'),
      components: [
        PreparedMealComponent(
          inventoryItemId: sourceItem.id,
          name: sourceItem.name,
          brand: sourceItem.brand,
          imageUrl: sourceItem.imageUrl,
          usedAmount: 200,
          usedUnit: InventoryAmountUnit.gram,
          totalKcal: 720,
          totalProtein: 14,
          totalCarbs: 158,
          totalFat: 2,
          sourceItemSnapshot: sourceItem,
        ),
      ],
    );

    final roundtrip = PreparedMeal.fromJson(meal.toJson());

    expect(roundtrip, meal);
    expect(roundtrip.imageAssetId, meal.imageAssetId);
    expect(roundtrip.components.single.sourceItemSnapshot, sourceItem);
  });

  test('PreparedMeal totals price proportionally for amount-based items', () {
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Soup',
      entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      initialQuantity: 2,
      unitPrice: 1.5,
      initialAmount: 1000,
      currentAmount: 600,
      amountUnit: InventoryAmountUnit.milliliter,
    );
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Soup bowl',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: [
        PreparedMealComponent(
          inventoryItemId: sourceItem.id,
          name: sourceItem.name,
          brand: sourceItem.brand,
          imageUrl: sourceItem.imageUrl,
          usedAmount: 250,
          usedUnit: InventoryAmountUnit.milliliter,
          totalKcal: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          sourceItemSnapshot: sourceItem,
        ),
      ],
    );

    expect(meal.components.single.totalPrice, closeTo(0.75, 0.0001));
    expect(meal.totalPrice, closeTo(0.75, 0.0001));
    expect(meal.perHundredAmountBasis, 250);
    expect(meal.perHundredMultiplier, closeTo(0.4, 0.0001));
  });

  test('PreparedMeal totals price by piece count for piece-based items', () {
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
  });

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
        initialAmount: 0,
        currentAmount: 0,
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

  test('PreparedMeal perHundredAmountBasis returns null for mixed units', () {
    final meal = _meal(
      components: <PreparedMealComponent>[
        _component(
          sourceItem: _sourceItem(id: 'rice', name: 'Rice'),
          usedAmount: 100,
          usedUnit: InventoryAmountUnit.gram,
        ),
        _component(
          sourceItem: _sourceItem(id: 'milk', name: 'Milk'),
          usedAmount: 200,
          usedUnit: InventoryAmountUnit.milliliter,
        ),
      ],
    );

    expect(meal.perHundredAmountBasis, isNull);
  });

  test('PreparedMeal without components has no basis and no total price', () {
    final meal = _meal();

    expect(meal.perHundredAmountBasis, isNull);
    expect(meal.totalPrice, 0);
  });
}
