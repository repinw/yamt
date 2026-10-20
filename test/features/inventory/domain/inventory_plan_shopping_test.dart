import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_shopping.dart';

InventoryPlanDemand _demand(
  Map<String, double> missingShareByPlanId, {
  Map<String, Map<String, int>> missingIngredientsByPlanId = const {},
  Map<String, List<PlanUnstockedIngredient>> unstockedIngredientsByPlanId =
      const {},
}) => (
  plannedByItemId: const {},
  missingByItemId: const {},
  plannedPortionsByMealId: const {},
  missingShareByPlanId: missingShareByPlanId,
  missingIngredientsByPlanId: missingIngredientsByPlanId,
  unstockedIngredientsByPlanId: unstockedIngredientsByPlanId,
  ownReservations: const [],
  othersByStockId: const {},
);

CalorieEntry _plan(String id, {ConsumedUnit unit = ConsumedUnit.grams}) {
  final day = DateTime(2026, 10, 8, 8);
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: id,
    brand: 'Brand',
    mealType: MealType.breakfast,
    consumedAmount: 400,
    consumedUnit: unit,
    per100Kcal: 100,
    per100Protein: 1,
    per100Carbs: 1,
    per100Fat: 1,
    sourceInventoryItemId: 'item',
    loggedAt: day,
    createdAt: day,
    updatedAt: day,
  );
}

CalorieEntry _recipePlan() {
  final day = DateTime(2026, 10, 8, 8);
  return CalorieEntry.bundle(
    id: 'recipe',
    userId: 'user-1',
    name: 'Pancakes',
    mealType: MealType.breakfast,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    bundleSourcePreparedMealId: 'pancakes',
    bundleConsumedPortions: 1,
    bundleTotalPortions: 2,
    bundleComponents: const [],
    loggedAt: day,
    createdAt: day,
    updatedAt: day,
  ).copyWith(
    bundleSourcePreparedMealId: null,
    bundleSourceTemplateId: 'pancakes',
  );
}

void main() {
  test('a short plan needs the part that no stock covers', () {
    final needs = inventoryShoppingPlanNeeds(
      [
        _plan('covered'),
        _plan('half'),
        _plan('milk', unit: ConsumedUnit.milliliters),
      ],
      _demand({'half': 0.5, 'milk': 1}),
      const [],
    );

    expect(needs.map((need) => need.name), ['half', 'milk']);
    expect(needs.first.amount, 200);
    expect(needs.first.isPartial, isTrue);
    expect(needs.first.inMilliliters, isFalse);
    expect(needs.first.brand, 'Brand');
    expect(needs.last.amount, 400);
    expect(needs.last.isPartial, isFalse);
    expect(needs.last.inMilliliters, isTrue);
  });

  test('a short plan of a cooked meal needs cooking, not shopping', () {
    final day = DateTime(2026, 10, 8, 18);
    final mealPlan = CalorieEntry.bundle(
      id: 'chili',
      userId: 'user-1',
      name: 'Chili',
      mealType: MealType.dinner,
      totalKcal: 500,
      totalProtein: 25,
      totalCarbs: 50,
      totalFat: 20,
      bundleSourcePreparedMealId: 'meal-1',
      bundleConsumedPortions: 1,
      bundleTotalPortions: 4,
      bundleComponents: const [],
      loggedAt: day,
      createdAt: day,
      updatedAt: day,
    );

    expect(
      inventoryShoppingPlanNeeds([mealPlan], _demand({'chili': 1}), const []),
      isEmpty,
    );
  });

  test('a short recipe plan needs each missing ingredient in grams', () {
    InventoryItem item(String id, InventoryAmountUnit unit) =>
        InventoryItem.create(
          id: id,
          name: id,
          brand: 'Brand',
          nutrition: const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Protein: 1,
            per100Carbs: 1,
            per100Fat: 1,
          ),
          entryDate: DateTime(2026, 9),
          storeName: 'Rewe',
          quantity: 1,
          initialAmount: 1000,
          amountUnit: unit,
        );

    final needs = inventoryShoppingPlanNeeds(
      [_recipePlan()],
      _demand(
        {'recipe': 0.5},
        missingIngredientsByPlanId: {
          'recipe': {'flour': 150, 'milk': 200, 'gone': 10},
        },
      ),
      [
        item('flour', InventoryAmountUnit.gram),
        item('milk', InventoryAmountUnit.milliliter),
      ],
    );

    expect(needs.map((need) => need.name), ['flour', 'milk']);
    expect(needs.map((need) => need.amount), [150, 200]);
    expect(needs.map((need) => need.inMilliliters), [false, true]);
    expect(needs.every((need) => need.isPartial), isTrue);
  });

  test('a recipe plan needs its ingredients without a Vorrat item', () {
    final plan = _recipePlan();

    final needs = inventoryShoppingPlanNeeds(
      [plan],
      _demand(
        {'recipe': 1},
        unstockedIngredientsByPlanId: {
          'recipe': [
            (name: 'Milch', amount: 150, inMilliliters: true),
            (name: 'Eier', amount: null, inMilliliters: false),
          ],
        },
      ),
      const [],
    );

    expect(needs.map((need) => need.name), ['Milch', 'Eier']);
    expect(needs.map((need) => need.amount), [150, null]);
    expect(needs.first.inMilliliters, isTrue);
    expect(needs.any((need) => need.isPartial), isFalse);
  });
}
