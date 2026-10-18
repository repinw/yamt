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
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

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
        )?.preparedMeal;
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

/// The stock [plan] of the Kochbuch [template] takes from each Vorrat item
/// in [items], by item id, in the item's stored unit: the recipe cooked on
/// paper from its assignments for the plan's cooked portions, or the
/// Vorlage's components, scaled to the portions the plan eats. Ingredients
/// without an item take nothing.
Map<String, int> templatePlanIngredientNeeds({
  required CalorieEntry plan,
  required PreparedMeal template,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required DateTime now,
}) {
  final cookedPortions = plan.bundleTotalPortions ?? template.totalPortions;
  final share = (plan.bundleConsumedPortions ?? 1) / max(1, cookedPortions);
  final whole = <String, int>{};
  if (template.recipeIngredients.isEmpty) {
    final ids = {for (final item in items) item.id};
    for (final component in template.components) {
      if (ids.contains(component.inventoryItemId)) {
        whole.update(
          component.inventoryItemId,
          (sum) => sum + component.usedAmount,
          ifAbsent: () => component.usedAmount,
        );
      }
    }
  } else {
    final cooked = _cookedOnPaper(
      template,
      cookedPortions: cookedPortions,
      assignments: templatePlanAssignments(template, items),
      items: items,
      parser: parser,
      now: now,
    );
    final before = {for (final item in _fullPacks(items)) item.id: item};
    for (final next in cooked?.nextItems ?? const <InventoryItem>[]) {
      final taken = before[next.id]!.availableAmount - next.availableAmount;
      if (taken > 0) {
        whole[next.id] = taken;
      }
    }
  }
  return {
    for (final MapEntry(key: id, value: amount) in whole.entries)
      if ((amount * share).ceil() case final needed when needed > 0) id: needed,
  };
}

/// The ingredients of the recipe [template] in [plan] that no Vorrat item in
/// [items] stands for, with their share of the recipe amount in grams or
/// milliliters when the line gives one. Ignored lines and Vorlagen have
/// none.
List<PlanUnstockedIngredient> templatePlanUnstockedIngredients({
  required CalorieEntry plan,
  required PreparedMeal template,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
}) {
  final cookedPortions = plan.bundleTotalPortions ?? template.totalPortions;
  final share = (plan.bundleConsumedPortions ?? 1) / max(1, cookedPortions);
  final assignments = templatePlanAssignments(template, items);
  return [
    for (final ingredient in template.recipeIngredients)
      if (!template.ignoredRecipeIngredients.contains(ingredient) &&
          (assignments[ingredient]?.isEmpty ?? true))
        _unstocked(
          ingredient,
          parser.parseRequirement(
            ingredient: ingredient,
            selectedPortions: max(1, cookedPortions),
            basePortions: max(1, template.totalPortions),
          ),
          share,
        ),
  ];
}

PlanUnstockedIngredient _unstocked(
  String ingredient,
  TemplateIngredientRequirement? requirement,
  double share,
) => switch (requirement?.unit) {
  TemplateIngredientUnit.gram || TemplateIngredientUnit.milliliter => (
    name: requirement!.name,
    amount: requirement.amount * share,
    inMilliliters: requirement.unit == TemplateIngredientUnit.milliliter,
  ),
  _ => (
    name: requirement?.name ?? ingredient.trim(),
    amount: null,
    inMilliliters: false,
  ),
};

// A plan takes no stock, so each item counts as a full pack.
List<InventoryItem> _fullPacks(List<InventoryItem> items) => [
  for (final item in items)
    item.copyWith(
      quantity: max(item.quantity, item.initialQuantity),
      currentAmount: max(item.currentAmount, item.initialAmount),
    ),
];

PreparedMealBuildResult? _cookedOnPaper(
  PreparedMeal recipe, {
  required int cookedPortions,
  required Map<String, List<String>> assignments,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required DateTime now,
}) {
  try {
    return buildPreparedMealCreationFromTemplateResult(
      currentItems: _fullPacks(items),
      preparedMealId: recipe.id,
      now: now,
      template: recipe.copyWith(totalPortions: max(1, recipe.totalPortions)),
      totalPortions: max(1, cookedPortions),
      recipeIngredientAssignments: assignments,
      recipeIngredientAmountConversions:
          recipe.recipeIngredientAmountConversions,
      ingredientParser: parser,
    );
  } on PreparedMealBuildException {
    // Every ingredient is ignored, so there is nothing to eat.
    return null;
  }
}
