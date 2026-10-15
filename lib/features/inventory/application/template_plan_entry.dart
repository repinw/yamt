import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_template.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// A plan of [portions] portions of the Kochbuch [template] on [loggedDay],
/// or null when it has nothing to plan.
///
/// A recipe is cooked on paper for [cookedPortions] portions from the
/// Vorrat items in [assignments]; an ingredient without an item leaves the
/// plan a reminder without kcal ([CalorieEntry.nutritionPending]). A Vorlage
/// keeps its own values.
///
/// shortcut: a plan takes no stock, so each assigned item counts as a full
/// pack; an ingredient that needs more than that stays open. Give the
/// template builder a no-stock mode when plans need several packs.
CalorieEntry? buildTemplatePlanEntry({
  required PreparedMeal template,
  required int cookedPortions,
  required Map<String, List<String>> assignments,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required MealType mealType,
  required DateTime loggedDay,
  required DateTime Function() now,
  required String Function() nextEntryId,
  num portions = 1,
}) {
  final meal = template.recipeIngredients.isEmpty
      ? template
      : _cookedOnPaper(
          template,
          cookedPortions: cookedPortions,
          assignments: assignments,
          items: items,
          parser: parser,
          now: now(),
        );
  if (meal == null) {
    return null;
  }
  return buildConsumedPreparedMealCalorieEntry(
    meal: meal,
    consumedPortions: portions,
    mealType: mealType,
    now: now,
    nextEntryId: nextEntryId,
    loggedDay: loggedDay,
  )?.copyWith(
    bundleSourcePreparedMealId: null,
    bundleSourceTemplateId: template.id,
  );
}

/// The saved Vorrat items in [items] of each ingredient of [recipe], or the
/// best name match for one without, like the recipe page picks them.
Map<String, List<String>> templatePlanAssignments(
  PreparedMeal recipe,
  List<InventoryItem> items,
) {
  final ids = {for (final item in items) item.id};
  return {
    for (final ingredient in recipe.recipeIngredients)
      ingredient: switch (<String>[
        for (final id
            in recipe.recipeIngredientAssignments[ingredient] ??
                const <String>[])
          if (ids.contains(id)) id,
      ]) {
        [] => [
          ?matchInventoryItemsForIngredient(
            ingredient: ingredient,
            inventoryItems: items,
          ).firstOrNull?.id,
        ],
        final saved => saved,
      },
  };
}

PreparedMeal? _cookedOnPaper(
  PreparedMeal recipe, {
  required int cookedPortions,
  required Map<String, List<String>> assignments,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required DateTime now,
}) {
  try {
    return buildPreparedMealCreationFromTemplateResult(
      currentItems: [
        for (final item in items)
          item.copyWith(
            quantity: max(item.quantity, item.initialQuantity),
            currentAmount: max(item.currentAmount, item.initialAmount),
          ),
      ],
      preparedMealId: recipe.id,
      now: now,
      template: recipe.copyWith(totalPortions: max(1, recipe.totalPortions)),
      totalPortions: max(1, cookedPortions),
      recipeIngredientAssignments: assignments,
      recipeIngredientAmountConversions:
          recipe.recipeIngredientAmountConversions,
      ingredientParser: parser,
    ).preparedMeal;
  } on PreparedMealBuildException {
    // Every ingredient is ignored, so there is nothing to eat.
    return null;
  }
}
