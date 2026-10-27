import 'dart:math' show max;

import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// The Vorrat items in [items] that supply each ingredient of [recipe], as
/// the recipe page picks them ([ingredientStockPick]). A plan cooks from
/// full packs, so a saved item stays even when it is used up.
///
/// shortcut: plans match with the lexicon of all languages; pass the app
/// locale when a plan needs one language's food words.
Map<String, List<String>> templatePlanAssignments(
  PreparedMeal recipe,
  List<InventoryItem> items, {
  required TemplateIngredientParser parser,
}) {
  return {
    for (final ingredient in recipe.recipeIngredients)
      ingredient: _planItems(recipe, ingredient, items, parser),
  };
}

/// One ingredient line of a recipe plan: the line, the Vorrat items it
/// counts with ([templatePlanAssignments]), and the items that could supply
/// it instead, best first.
typedef TemplatePlanIngredient = ({
  String ingredient,
  List<InventoryItem> items,
  List<InventoryItem> candidates,
});

/// The ingredient lines of [recipe] that are not ignored, each with the
/// Vorrat items in [items] it counts with in a plan and its other
/// candidates.
List<TemplatePlanIngredient> templatePlanIngredients(
  PreparedMeal recipe,
  List<InventoryItem> items, {
  required TemplateIngredientParser parser,
}) => [
  for (final ingredient in recipe.recipeIngredients)
    if (!recipe.ignoredRecipeIngredients.contains(ingredient))
      _planIngredient(recipe, ingredient, items, parser),
];

List<String> _planItems(
  PreparedMeal recipe,
  String ingredient,
  List<InventoryItem> items,
  TemplateIngredientParser parser,
) => [
  for (final item in _planIngredient(recipe, ingredient, items, parser).items)
    item.id,
];

TemplatePlanIngredient _planIngredient(
  PreparedMeal recipe,
  String ingredient,
  List<InventoryItem> items,
  TemplateIngredientParser parser,
) {
  final saved =
      recipe.recipeIngredientAssignments[ingredient] ?? const <String>[];
  final candidates = ingredientStockCandidates(
    text: ingredient,
    requirement: parser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: 1,
      basePortions: 1,
    ),
    items: [
      for (final item in items)
        if (saved.contains(item.id)) templatePlanFullPack(item) else item,
    ],
    localeCode: null,
    amountConversion:
        recipe.recipeIngredientAmountConversions[ingredient.trim()],
  );
  return (
    ingredient: ingredient,
    items: ingredientStockPick(
      recipe: recipe,
      text: ingredient,
      candidates: candidates,
    ),
    candidates: [...candidates.matches, ...candidates.others],
  );
}

/// [item] as a full pack: a plan takes no stock, so it cooks from full
/// packs.
InventoryItem templatePlanFullPack(InventoryItem item) => item.copyWith(
  quantity: max(item.quantity, item.initialQuantity),
  currentAmount: max(item.currentAmount, item.initialAmount),
);
