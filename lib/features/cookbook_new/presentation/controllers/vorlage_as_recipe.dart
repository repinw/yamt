import 'dart:math' show max;

import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// The foods of the Vorlage [vorlage] for its own portions, each with the
/// recipe line that shows it on the page. Packs of the same food count as
/// one food, with all the Vorrat items they came from.
List<({String line, VorlageFood food})> vorlageFoods(
  PreparedMeal vorlage,
  TemplateIngredientParser parser,
) {
  final foods = <(String, InventoryAmountUnit), VorlageFood>{};
  for (final component in vorlage.components) {
    // Without a pack size in the name of a piece food, which the parser
    // would read as the amount ("2 Mozzarella", not "2 Mozzarella 125 g").
    final unit = component.usedUnit;
    final name = unit == InventoryAmountUnit.piece
        ? parser
                  .parseRequirement(
                    ingredient: component.name,
                    selectedPortions: 1,
                    basePortions: 1,
                  )
                  ?.name ??
              component.name
        : component.name;
    final amount = preparedMealComponentDisplayAmount(component);
    foods.update(
      (name, unit),
      (food) => (
        name: name,
        unit: unit,
        amount: food.amount + amount,
        itemIds: [...food.itemIds, component.inventoryItemId],
      ),
      ifAbsent: () => (
        name: name,
        unit: unit,
        amount: amount,
        itemIds: [component.inventoryItemId],
      ),
    );
  }
  return [
    for (final food in foods.values)
      (
        // The parser counts whole pieces, so the line shows at least one;
        // cooking takes the food's own amount.
        line: preparedMealFoodRow(
          food.unit == InventoryAmountUnit.piece
              ? max<double>(1, food.amount)
              : food.amount,
          food.unit,
          food.name,
        ),
        food: food,
      ),
  ];
}

/// The Vorlage [vorlage] as a recipe: one ingredient per food, with the
/// Vorrat items it was combined from, so the page sizes it like a recipe.
PreparedMeal vorlageAsRecipe(
  PreparedMeal vorlage,
  TemplateIngredientParser parser,
) {
  final foods = vorlageFoods(vorlage, parser);
  return vorlage.copyWith(
    recipeIngredients: [for (final (:line, food: _) in foods) line],
    recipeIngredientAssignments: {
      for (final (:line, :food) in foods) line: food.itemIds,
    },
  );
}
