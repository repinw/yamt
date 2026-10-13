import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

PreparedMeal preparedMealTestData({
  String id = 'meal-1',
  String name = 'Rice bowl',
  String? imageAssetId,
  int totalPortions = 3,
  num remainingPortions = 2,
}) {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
  );

  return PreparedMeal(
    id: id,
    name: name,
    imageAssetId: imageAssetId,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 8,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 100,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 400,
        totalProtein: 20,
        totalCarbs: 40,
        totalFat: 8,
        sourceItemSnapshot: sourceItem,
      ),
    ],
  );
}

/// Rice with a complete EU label: per 100 g 350 kcal, 1 g fat (0.5 g
/// saturates), 75 g carbs (1 g sugar), 2 g fibre, 8 g protein, 0.25 g salt.
const riceLabelTestData = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 350,
  per100Fat: 1,
  per100SaturatedFat: 0.5,
  per100Carbs: 75,
  per100Sugar: 1,
  per100Fiber: 2,
  per100Protein: 8,
  per100Salt: 0.25,
);

/// A tomato sauce whose label has only energy and the macros: per 100 g
/// 50 kcal, 2 g fat, 6 g carbs, 1.5 g protein.
const sauceLabelTestData = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
  per100Kcal: 50,
  per100Fat: 2,
  per100Carbs: 6,
  per100Protein: 1.5,
);

/// A Vorrat food counted in grams, with [grams] in stock and the per-100
/// [label].
InventoryItem labeledFoodTestData({
  required String id,
  required String name,
  required int grams,
  required GlobalFoodNutrition label,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: grams,
    currentAmount: grams,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: label,
  );
}

/// [grams] of [item] as a meal ingredient, counted as cooking counts it.
PreparedMealComponent labeledIngredientTestData(InventoryItem item, int grams) {
  return buildPreparedMealComponent(
    item: item,
    usedAmount: grams,
    usedUnit: InventoryAmountUnit.gram,
    nutrition: item.nutrition!,
  );
}

/// The cooked meal "Reispfanne" of [ingredients] with their totals, and the
/// open rows [pending].
PreparedMeal labeledMealTestData({
  required List<PreparedMealComponent> ingredients,
  List<String> pending = const <String>[],
  int totalPortions = 1,
}) {
  final totals = ingredients.nutritionTotals;
  return PreparedMeal(
    id: 'pan',
    name: 'Reispfanne',
    totalPortions: totalPortions,
    remainingPortions: totalPortions,
    totalKcal: totals.totalKcal,
    totalProtein: totals.totalProtein,
    totalCarbs: totals.totalCarbs,
    totalFat: totals.totalFat,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: ingredients,
    recipeIngredients: pending,
    pendingRecipeIngredients: pending,
  );
}
