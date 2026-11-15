import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
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
  RecipeEstimate? estimate,
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
  recipeEstimate: estimate,
);

RecipeEstimate _estimate(List<String> lines, {int portions = 2}) =>
    RecipeEstimate(
      kcal: 450,
      protein: 30,
      carbs: 40,
      fat: 12,
      portions: portions,
      linesKey: recipeLinesKey(lines),
      createdAt: _now,
    );

CalorieEntry? _planOf(
  PreparedMeal template, {
  List<InventoryItem> items = const [],
  Map<String, List<String>> assignments = const {},
  num portions = 1,
}) => buildTemplatePlanEntry(
  template: template,
  cookedPortions: template.totalPortions,
  assignments: assignments,
  items: items,
  parser: const TemplateIngredientParser(),
  mealType: MealType.dinner,
  loggedDay: DateTime(2026, 10, 19),
  now: () => _now,
  nextEntryId: () => 'plan',
  portions: portions,
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
      _template(
        ingredients: const ['Salz', 'Pfeffer'],
        // The recipe page offers no item of another name, so neither does
        // the plan.
        assignments: const {
          'Pfeffer': ['Salz'],
        },
      ),
      [_item('Salz', currentAmount: 500)],
      parser: const TemplateIngredientParser(),
    );

    expect(assignments, {
      'Salz': ['Salz'],
      'Pfeffer': <String>[],
    });
  });

  group('buildTemplatePlanEntry with the recipe estimate', () {
    const lines = ['200 g Mehl', '2 Eier'];

    test('plans one portion of the estimate while an ingredient has no '
        'Vorrat item', () {
      final plan = _planOf(
        _template(ingredients: lines, estimate: _estimate(lines)),
      )!;

      expect(plan.nutritionEstimated, isTrue);
      expect(plan.nutritionPending, isFalse);
      expect(plan.totalKcal, 450);
      expect(plan.totalProtein, 30);
      expect(plan.totalCarbs, 40);
      expect(plan.totalFat, 12);
      // A meal plan counts as 100 g, so its values per 100 are its totals.
      expect(plan.per100Kcal, 450);
      expect(plan.per100Fat, 12);
      expect(plan.bundleSourceTemplateId, 'pancakes');
      expect(plan.bundleSourcePreparedMealId, isNull);
      expect(plan.bundleConsumedPortions, 1);
    });

    test('a partly stocked recipe counts as a portion of the recipe, without '
        'the foods that have an item', () {
      final plan = _planOf(
        _template(ingredients: lines, estimate: _estimate(lines)),
        items: [_item('flour', currentAmount: 500)],
        assignments: const {
          '200 g Mehl': ['flour'],
        },
      )!;

      expect(plan.nutritionEstimated, isTrue);
      expect(plan.totalKcal, 450);
      expect(plan.isCombined, isFalse);
      expect(plan.bundleComponents, isEmpty);
      expect(plan.bundleConsumedPortions, 1);
      expect(plan.bundleTotalPortions, 2);
    });

    test('scales the estimate to the portions the plan eats', () {
      final plan = _planOf(
        _template(ingredients: lines, estimate: _estimate(lines)),
        portions: 2,
      )!;

      expect(plan.nutritionEstimated, isTrue);
      expect(plan.totalKcal, 900);
      expect(plan.totalProtein, 60);
      expect(plan.per100Kcal, 900);
    });

    test('stays a reminder without kcal when the estimate no longer fits '
        'the lines or the portions', () {
      final changedLines = _planOf(
        _template(ingredients: [...lines, 'Salz'], estimate: _estimate(lines)),
      )!;
      final changedPortions = _planOf(
        _template(ingredients: lines, estimate: _estimate(lines, portions: 4)),
      )!;

      for (final plan in [changedLines, changedPortions]) {
        expect(plan.nutritionPending, isTrue);
        expect(plan.nutritionEstimated, isFalse);
        expect(plan.totalKcal, 0);
      }
    });

    test('stays a reminder without kcal when the recipe has no estimate', () {
      final plan = _planOf(_template(ingredients: lines))!;

      expect(plan.nutritionPending, isTrue);
      expect(plan.nutritionEstimated, isFalse);
      expect(plan.totalKcal, 0);
    });

    test(
      'the values of the Vorrat items win once every ingredient has one',
      () {
        const oneLine = ['200 g Mehl'];
        final plan = _planOf(
          _template(ingredients: oneLine, estimate: _estimate(oneLine)),
          items: [_item('flour', currentAmount: 500)],
          assignments: const {
            '200 g Mehl': ['flour'],
          },
        )!;

        // One of two portions of 200 g flour: 100 g at 350 kcal.
        expect(plan.nutritionEstimated, isFalse);
        expect(plan.nutritionPending, isFalse);
        expect(plan.totalKcal, closeTo(350, 0.01));
      },
    );

    test('a Vorlage keeps its own values, whatever estimate it holds', () {
      final plan = _planOf(_template(estimate: _estimate(const [])))!;

      expect(plan.nutritionEstimated, isFalse);
      expect(plan.totalKcal, 350);
    });
  });

  test('an estimated plan stores the key, any other plan does not', () {
    const lines = ['200 g Mehl'];
    final estimated = _planOf(
      _template(ingredients: lines, estimate: _estimate(lines)),
    )!;
    final reminder = _planOf(_template(ingredients: lines))!;

    expect(estimated.toJson()['nutrition_estimated'], isTrue);
    expect(reminder.toJson().containsKey('nutrition_estimated'), isFalse);
    expect(
      CalorieEntry.fromJson(estimated.toJson()).nutritionEstimated,
      isTrue,
    );
    expect(
      CalorieEntry.fromJson(reminder.toJson()).nutritionEstimated,
      isFalse,
    );
  });

  group('replanTemplatePlan', () {
    test('turns an estimated plan into one with the Vorrat values and keeps '
        'its identity', () {
      const lines = ['200 g Mehl'];
      final template = _template(
        ingredients: lines,
        estimate: _estimate(lines),
      );
      final estimated = _planOf(template)!.copyWith(userId: 'user-1');

      final counted = replanTemplatePlan(
        estimated,
        template,
        items: [_item('flour', currentAmount: 500).copyWith(name: 'Mehl')],
        parser: const TemplateIngredientParser(),
      )!;

      expect(estimated.nutritionEstimated, isTrue);
      expect(counted.nutritionEstimated, isFalse);
      expect(counted.totalKcal, closeTo(350, 0.01));
      expect(counted.id, 'plan');
      expect(counted.userId, 'user-1');
      expect(counted.loggedAt, estimated.loggedAt);
    });

    test('gives an estimated plan nothing when its items give no kcal and the '
        'estimate no longer fits', () {
      const before = ['200 g Mehl'];
      final estimated = _planOf(
        _template(ingredients: before, estimate: _estimate(before)),
      )!;
      expect(estimated.nutritionEstimated, isTrue);

      final replanned = replanTemplatePlan(
        estimated,
        _template(ingredients: const ['Salz'], estimate: _estimate(before)),
        items: [_item('Salz', currentAmount: 500)],
        parser: const TemplateIngredientParser(),
      );

      expect(replanned, isNull);
    });

    test('counts a reminder at 0 kcal when its items give no kcal', () {
      final template = _template(ingredients: const ['Salz']);
      final reminder = _planOf(template)!;
      expect(reminder.nutritionPending, isTrue);

      final counted = replanTemplatePlan(
        reminder,
        template,
        items: [_item('Salz', currentAmount: 500)],
        parser: const TemplateIngredientParser(),
      )!;

      expect(counted.nutritionPending, isFalse);
      expect(counted.totalKcal, 0);
    });
  });
}
