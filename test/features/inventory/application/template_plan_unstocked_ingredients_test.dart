import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/template_plan_unstocked_ingredients.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

final _now = DateTime(2026, 10, 18, 9);

void main() {
  test('a recipe plan names its ingredients without a Vorrat item', () {
    final unstocked = templatePlanUnstockedIngredients(
      plan: CalorieEntry.bundle(
        id: 'plan',
        userId: 'user-1',
        name: 'Pancakes',
        mealType: MealType.breakfast,
        totalKcal: 350,
        totalProtein: 10,
        totalCarbs: 70,
        totalFat: 2,
        bundleSourcePreparedMealId: 'pancakes',
        bundleConsumedPortions: 1,
        bundleTotalPortions: 2,
        bundleComponents: const [],
        loggedAt: _now,
        createdAt: _now,
        updatedAt: _now,
      ),
      template: PreparedMeal(
        id: 'pancakes',
        name: 'Pancakes',
        totalPortions: 2,
        remainingPortions: 2,
        totalKcal: 700,
        totalProtein: 20,
        totalCarbs: 140,
        totalFat: 4,
        createdAt: DateTime(2026, 10),
        updatedAt: DateTime(2026, 10),
        components: const <PreparedMealComponent>[],
        recipeIngredients: const ['200 g Mehl', '300 ml Milch', '2 Eier'],
        recipeIngredientAssignments: const {
          '200 g Mehl': ['flour'],
        },
      ),
      items: [
        InventoryItem.create(
          id: 'flour',
          name: 'flour',
          nutrition: const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 350,
            per100Protein: 10,
            per100Carbs: 70,
            per100Fat: 2,
          ),
          entryDate: DateTime(2026, 9),
          storeName: 'Rewe',
          quantity: 1,
          initialAmount: 1000,
          currentAmount: 50,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ],
      parser: const TemplateIngredientParser(),
    );

    expect(unstocked, hasLength(2));
    expect(unstocked.first.name, 'Milch');
    expect(unstocked.first.amount, 150);
    expect(unstocked.first.inMilliliters, isTrue);
    expect(unstocked.last.amount, isNull);
  });
}
