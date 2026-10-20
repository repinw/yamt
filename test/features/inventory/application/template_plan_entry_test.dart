import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

final _now = DateTime(2026, 10, 18, 9);

InventoryItem _item(String id, {required int currentAmount}) =>
    InventoryItem.create(
      id: id,
      name: id,
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
      currentAmount: currentAmount,
      amountUnit: InventoryAmountUnit.gram,
    );

PreparedMeal _template({
  List<String> ingredients = const [],
  Map<String, List<String>> assignments = const {},
  List<PreparedMealComponent> components = const [],
}) => PreparedMeal(
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
  components: components,
  recipeIngredients: ingredients,
  recipeIngredientAssignments: assignments,
);

CalorieEntry _plan({int consumed = 1, int total = 2}) => CalorieEntry.bundle(
  id: 'plan',
  userId: 'user-1',
  name: 'Pancakes',
  mealType: MealType.breakfast,
  totalKcal: 350,
  totalProtein: 10,
  totalCarbs: 70,
  totalFat: 2,
  bundleSourcePreparedMealId: 'pancakes',
  bundleConsumedPortions: consumed,
  bundleTotalPortions: total,
  bundleComponents: const [],
  loggedAt: _now,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  test('a recipe plan needs its share of each assigned ingredient', () {
    final needs = templatePlanIngredientNeeds(
      plan: _plan(),
      template: _template(
        ingredients: const ['200 g Mehl', '1 Prise Salz'],
        assignments: const {
          '200 g Mehl': ['flour'],
        },
      ),
      // Planning counts a full pack, not the 50 g left in it.
      items: [_item('flour', currentAmount: 50)],
      parser: const TemplateIngredientParser(),
      now: _now,
    );

    expect(needs, {'flour': 100});
  });

  test('a Vorlage plan needs its components that are still stocked', () {
    PreparedMealComponent component(String itemId) => PreparedMealComponent(
      inventoryItemId: itemId,
      name: itemId,
      brand: null,
      imageUrl: null,
      usedAmount: 300,
      usedUnit: InventoryAmountUnit.gram,
      totalKcal: 1000,
      totalProtein: 30,
      totalCarbs: 200,
      totalFat: 6,
      sourceItemSnapshot: _item(itemId, currentAmount: 300),
    );

    final needs = templatePlanIngredientNeeds(
      plan: _plan(),
      template: _template(components: [component('flour'), component('gone')]),
      items: [_item('flour', currentAmount: 0)],
      parser: const TemplateIngredientParser(),
      now: _now,
    );

    expect(needs, {'flour': 150});
  });

  test('a recipe plan names its ingredients without a Vorrat item', () {
    final unstocked = templatePlanUnstockedIngredients(
      plan: _plan(),
      template: _template(
        ingredients: const ['200 g Mehl', '300 ml Milch', '2 Eier'],
        assignments: const {
          '200 g Mehl': ['flour'],
        },
      ),
      items: [_item('flour', currentAmount: 50)],
      parser: const TemplateIngredientParser(),
    );

    expect(unstocked, hasLength(2));
    expect(unstocked.first.name, 'Milch');
    expect(unstocked.first.amount, 150);
    expect(unstocked.first.inMilliliters, isTrue);
    expect(unstocked.last.amount, isNull);
  });

  test('a plan takes the item that fits, like the recipe page', () {
    InventoryItem milk(String id, InventoryAmountUnit unit) => _item(
      id,
      currentAmount: 1000,
    ).copyWith(name: 'Milch', amountUnit: unit);

    final assignments = templatePlanAssignments(
      _template(
        ingredients: const ['300 ml Milch', '200 g Mehl'],
        // The saved item is kept in grams now and no longer fits.
        assignments: const {
          '300 ml Milch': ['milk-g'],
        },
      ),
      [
        milk('milk-g', InventoryAmountUnit.gram),
        milk('milk-ml', InventoryAmountUnit.milliliter),
      ],
      parser: const TemplateIngredientParser(),
    );

    expect(assignments, {
      '300 ml Milch': ['milk-ml'],
      '200 g Mehl': <String>[],
    });
  });

  test('a used-up saved item still serves a plan, which cooks from full '
      'packs', () {
    final assignments = templatePlanAssignments(
      _template(
        ingredients: const ['200 g flour'],
        assignments: const {
          '200 g flour': ['flour'],
        },
      ),
      [_item('flour', currentAmount: 0)],
      parser: const TemplateIngredientParser(),
    );

    expect(assignments, {
      '200 g flour': ['flour'],
    });
  });

  test('a food that names no amount takes the item of its name', () {
    final assignments = templatePlanAssignments(
      _template(ingredients: const ['Salz', 'Pfeffer']),
      [_item('Salz', currentAmount: 500)],
      parser: const TemplateIngredientParser(),
    );

    expect(assignments, {
      'Salz': ['Salz'],
      'Pfeffer': <String>[],
    });
  });
}
