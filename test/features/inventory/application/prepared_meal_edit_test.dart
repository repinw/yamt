import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_edit.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/'
    'prepared_meal_item_components.dart';

void main() {
  final now = DateTime(2026, 10, 27);

  group('one Vorrat item that fills two rows', () {
    // The meal took 150 g of 1000 g: 100 g for one row, 50 g for another.
    final flour = _item(id: 'flour', name: 'Mehl', currentAmount: 850);
    final meal = _meal(
      components: [
        _component(flour, 100, row: '100 g Mehl'),
        _component(flour, 50, row: '50 g Mehl'),
      ],
    );

    test('counts as one food in the editor', () {
      final merged = preparedMealComponentsByItem(meal.components).single;

      expect(merged.usedAmount, 150);
      expect(merged.totalKcal, 150);
      // Two rows: a merged food names neither.
      expect(merged.pendingRecipeIngredient, isNull);
    });

    test('scales both components together and keeps their rows', () {
      final result = buildPreparedMealEditResult(
        currentMeal: meal,
        currentItems: [flour],
        now: now,
        name: meal.name,
        imageChanged: false,
        imageAssetId: null,
        totalPortions: 1,
        inputs: const [PreparedMealItemInput(itemId: 'flour', usedAmount: 300)],
      );

      final components = result.preparedMeal.components;
      expect([for (final c in components) c.usedAmount], [200, 100]);
      expect(
        [for (final c in components) c.pendingRecipeIngredient],
        ['100 g Mehl', '50 g Mehl'],
      );
      expect(result.preparedMeal.totalKcal, 300);
      expect(result.nextItems.single.currentAmount, 700);
    });
  });

  test('a food added in the editor closes a row without an amount', () {
    final salt = _item(id: 'salt', name: 'Salz', currentAmount: 500);
    final meal = _meal(
      components: const [],
      pendingRecipeIngredients: const ['Salz'],
    );

    final result = buildPreparedMealEditResult(
      currentMeal: meal,
      currentItems: [salt],
      now: now,
      name: meal.name,
      imageChanged: false,
      imageAssetId: null,
      totalPortions: 1,
      inputs: const [PreparedMealItemInput(itemId: 'salt', usedAmount: 5)],
    );

    expect(result.preparedMeal.pendingRecipeIngredients, isEmpty);
    expect(
      result.preparedMeal.components.single.pendingRecipeIngredient,
      'Salz',
    );
  });

  test('a food given its own values keeps the row it filled', () {
    final pasta = _item(id: 'pasta', name: 'Fusilli', currentAmount: 350);
    final meal = _meal(
      components: [_component(pasta, 150, row: '150 g Nudeln')],
    );

    final result = buildPreparedMealEditResult(
      currentMeal: meal,
      currentItems: [pasta],
      now: now,
      name: meal.name,
      imageChanged: false,
      imageAssetId: null,
      totalPortions: 1,
      inputs: const [
        PreparedMealItemInput(
          itemId: 'pasta',
          usedAmount: 150,
          manualNutrition: _nutrition,
        ),
      ],
    );

    expect(
      result.preparedMeal.components.single.pendingRecipeIngredient,
      '150 g Nudeln',
    );
  });
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
);

InventoryItem _item({
  required String id,
  required String name,
  required int currentAmount,
}) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime(2026, 10, 20),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: currentAmount,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: _nutrition,
);

PreparedMealComponent _component(
  InventoryItem item,
  int amount, {
  required String row,
}) => PreparedMealComponent(
  inventoryItemId: item.id,
  name: item.name,
  brand: item.brand,
  imageUrl: item.imageUrl,
  usedAmount: amount,
  usedUnit: InventoryAmountUnit.gram,
  totalKcal: amount.toDouble(),
  totalProtein: amount / 10,
  totalCarbs: amount / 5,
  totalFat: amount / 20,
  sourceItemSnapshot: item,
  pendingRecipeIngredient: row,
);

PreparedMeal _meal({
  required List<PreparedMealComponent> components,
  List<String> pendingRecipeIngredients = const [],
}) => PreparedMeal(
  id: 'meal',
  name: 'Kuchen',
  totalPortions: 1,
  remainingPortions: 1,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime(2026, 10, 20),
  updatedAt: DateTime(2026, 10, 20),
  components: components,
  pendingRecipeIngredients: pendingRecipeIngredients,
);
