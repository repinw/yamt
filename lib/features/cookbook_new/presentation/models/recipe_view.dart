import 'dart:math' show max;

import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

/// One ingredient of a recipe, sized for the chosen portions.
@immutable
class RecipeIngredientLine {
  /// Creates the line for [ingredient].
  const new({
    required this.ingredient,
    required this.row,
    required this.isIgnored,
    this.items = const <InventoryItem>[],
  });

  /// The saved ingredient, written for the recipe's own portions; the key of
  /// [RecipeView.assignments].
  final String ingredient;

  /// The ingredient for the chosen portions.
  final RecipeIngredientRow row;

  /// Whether the recipe ignores the ingredient, like salt or water.
  final bool isIgnored;

  /// The Vorrat items that supply it this time, in the order they are used.
  final List<InventoryItem> items;
}

/// A recipe as the recipe page shows it.
@immutable
class RecipeView {
  /// Creates the view of [recipe] for [portions].
  const new({
    required this.recipe,
    required this.portions,
    required this.lines,
    PreparedMeal? saved,
  }) : saved = saved ?? recipe;

  /// The recipe as the page shows it; a Vorlage as one ingredient per food.
  final PreparedMeal recipe;

  /// The recipe as it is saved.
  final PreparedMeal saved;

  /// The portions to cook.
  final int portions;

  /// The ingredients for [portions].
  final List<RecipeIngredientLine> lines;

  /// The portions the recipe is written for; a recipe needs at least one to
  /// scale from.
  int get basePortions => max(1, recipe.totalPortions);

  /// The ingredients that count, without the ignored ones.
  Iterable<RecipeIngredientLine> get activeLines =>
      lines.where((line) => !line.isIgnored);

  /// Whether the Vorrat supplies any of the ingredients.
  bool get anyLineInStock => lines.any((line) => line.items.isNotEmpty);

  /// Whether this is a Vorlage combined from Vorrat foods, which shows its
  /// foods as ingredients.
  bool get isVorlage => saved.recipeIngredients.isEmpty;

  /// The AI's estimate per portion while it fits the saved ingredient lines
  /// and portions; `null` before it comes and after they change.
  RecipeEstimate? get estimate => saved.fittingRecipeEstimate;

  /// The [estimate] of one portion as its food label shows it: energy, fat,
  /// carbohydrates, and protein, in whole kcal and grams, since the AI only
  /// guesses them; `null` without an estimate.
  NutritionFacts? get portionFacts => switch (estimate) {
    final estimate? => NutritionFacts(
      kcal: estimate.kcal.roundToDouble(),
      fat: estimate.fat.roundToDouble(),
      carbs: estimate.carbs.roundToDouble(),
      protein: estimate.protein.roundToDouble(),
    ),
    null => null,
  };

  /// The kcal and macros of each ingredient for [portions], by its food
  /// alone as the Kochmodus names it (`cookLineFoodName`: "Knoblauch" for "2
  /// Zehen Knoblauch", "Salz" for "1 Prise Salz", "Zitrone" for "½ Zitrone"),
  /// while the [estimate] has them per line; `null` without them.
  List<({String food, RecipeLineNutrition nutrition})>? get lineNutrition {
    final perLine = estimate?.lines;
    if (perLine == null || perLine.length != lines.length) {
      return null;
    }
    final factor = portions / basePortions;
    return [
      for (final (index, line) in lines.indexed)
        (
          food: cookLineFoodName(line.ingredient),
          nutrition: perLine[index].scaled(factor),
        ),
    ];
  }

  /// The Vorrat items to use up, by the ingredient of [recipe].
  Map<String, List<String>> get assignments => {
    for (final line in activeLines)
      if (line.items.isNotEmpty)
        line.ingredient: [for (final item in line.items) item.id],
  };
}
