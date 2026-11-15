import 'dart:math' show max;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

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
  final assignments = templatePlanAssignments(template, items, parser: parser);
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
