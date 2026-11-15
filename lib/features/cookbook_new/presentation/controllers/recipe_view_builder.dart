import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/vorlage_as_recipe.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The recipe [recipeId] from [templates] with its ingredients for
/// [portions] (`null` for its own) and their Vorrat [items], or `null` when
/// the recipe is gone. It loads and fails with [templates] and [items]. A
/// recipe with a running cook run takes its [runPortions] instead; a Vorlage
/// has no cook run.
///
/// An ingredient takes the items the recipe saved that can still supply it,
/// else the best match.
AsyncValue<RecipeView?> buildRecipeView({
  required String recipeId,
  required AsyncValue<List<PreparedMeal>> templates,
  required AsyncValue<List<InventoryItem>> items,
  required TemplateIngredientParser parser,
  required String localeCode,
  required int? portions,
  int? runPortions,
}) {
  for (final async in [templates, items]) {
    if (async case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  // The previous values carry the page through a reload.
  final saved = templates.value;
  final vorrat = items.value;
  if (saved == null || vorrat == null) {
    return const AsyncLoading();
  }
  final stored = saved.firstWhereOrNull((meal) => meal.id == recipeId);
  if (stored == null) {
    return const AsyncData(null);
  }
  final isVorlage = stored.recipeIngredients.isEmpty;
  final recipe = isVorlage ? vorlageAsRecipe(stored, parser) : stored;
  // A Vorlage food is sized from its own amount, as cooking takes it.
  final vorlageFoodByLine = {
    if (isVorlage)
      for (final (:line, :food) in vorlageFoods(stored, parser)) line: food,
  };
  // A recipe needs at least one portion to scale from.
  final basePortions = max(1, recipe.totalPortions);
  final chosen = (isVorlage ? null : runPortions) ?? portions ?? basePortions;

  return AsyncData(
    RecipeView(
      recipe: recipe,
      saved: stored,
      portions: chosen,
      lines: [
        for (final ingredient in recipe.recipeIngredients)
          _line(
            ingredient: ingredient,
            recipe: recipe,
            requirement: switch (vorlageFoodByLine[ingredient]) {
              final food? => TemplateIngredientRequirement(
                // Matching counts whole pieces.
                amount: max(1, (food.amount * chosen / basePortions).round()),
                unit: food.unit.toTemplateIngredientUnit(),
                name: food.name,
              ),
              // Read like the Kochmodus reads the line.
              null => parser.parseRequirement(
                ingredient: ingredient,
                selectedPortions: chosen,
                basePortions: basePortions,
              ),
            },
            // The row says a part of a unit as exactly as the Kochmodus.
            shown: vorlageFoodByLine.containsKey(ingredient)
                ? null
                : parseIngredientExactly(
                    parser,
                    ingredient,
                    selectedPortions: chosen,
                    basePortions: basePortions,
                  ),
            items: vorrat,
            localeCode: localeCode,
          ),
      ],
    ),
  );
}

RecipeIngredientLine _line({
  required String ingredient,
  required PreparedMeal recipe,
  required TemplateIngredientRequirement? requirement,
  required TemplateIngredientRequirement? shown,
  required List<InventoryItem> items,
  required String localeCode,
}) {
  final found = ingredientStockCandidates(
    text: ingredient,
    requirement: requirement,
    items: items,
    localeCode: localeCode,
    amountConversion:
        recipe.recipeIngredientAmountConversions[ingredient.trim()],
  );
  final stock = ingredientStockPick(
    recipe: recipe,
    text: ingredient,
    candidates: found,
  );
  return RecipeIngredientLine(
    ingredient: ingredient,
    row: RecipeIngredientRow(
      text: ingredient,
      requirement: requirement == null ? null : shown ?? requirement,
    ),
    isIgnored: recipe.ignoredRecipeIngredients.contains(ingredient),
    items: stock,
  );
}
