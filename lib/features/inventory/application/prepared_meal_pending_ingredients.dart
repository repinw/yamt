import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_row_share.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Consumes inventory to fill one pending template ingredient entry. A row
/// that names no amount ("Salz") is done once one of the items stands for
/// it, and takes nothing, as when a recipe is cooked (#834).
PreparedMealPendingIngredientFillResult?
buildPreparedMealPendingIngredientFillResult({
  required List<InventoryItem> currentItems,
  required String ingredient,
  required List<String> inventoryItemIds,
  required TemplateIngredientParser ingredientParser,
}) {
  final requirement = ingredientParser.parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (requirement == null) {
    return ingredientNamesNoAmount(ingredient) &&
            currentItems.any((item) => inventoryItemIds.contains(item.id))
        ? PreparedMealPendingIngredientFillResult(
            nextItems: currentItems,
            components: const [],
          )
        : null;
  }

  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  var remainingAmount = requirement.amount;
  var consumedAnyAmount = false;
  final requiredUnit = requirement.inventoryUnit;

  for (final itemId in inventoryItemIds) {
    if (remainingAmount <= 0) {
      break;
    }

    final itemIndex = nextItems.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) {
      continue;
    }

    final currentItem = nextItems[itemIndex];
    // Pieces never come from an item kept in grams (#860).
    if (!ingredientItemFits(currentItem, requirement) ||
        !hasCompatibleTemplateRequirement(
          item: currentItem,
          requiredUnit: requiredUnit,
        )) {
      continue;
    }

    final consumableAmount = consumableAmountForRequirement(
      item: currentItem,
      requiredUnit: requiredUnit,
      remainingAmount: remainingAmount,
    );
    if (consumableAmount < 1) {
      continue;
    }

    final nextItem = currentItem.reducedBy(consumableAmount);
    if (nextItem == null) {
      continue;
    }

    final resolvedNutrition =
        currentItem.nutrition ??
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.missing,
        );
    final nextRemainingAmount = remainingRequirementAfterConsumption(
      item: currentItem,
      requiredUnit: requiredUnit,
      remainingAmount: remainingAmount,
      consumedAmount: consumableAmount,
    );
    nextItems[itemIndex] = nextItem;
    components.add(
      buildPreparedMealComponent(
        item: currentItem,
        usedAmount: consumableAmount,
        usedUnit: resolveTemplateUsedUnit(
          item: currentItem,
          requiredUnit: requiredUnit,
        ),
        nutrition: resolvedNutrition,
      ).copyWith(
        pendingRecipeIngredient: filledRowShare(
          row: ingredient,
          covered: remainingAmount - nextRemainingAmount,
          needed: requirement.amount,
          unit: requirement.unit,
          name: requirement.name,
          parser: ingredientParser,
        ),
      ),
    );
    remainingAmount = nextRemainingAmount;
    consumedAnyAmount = true;
  }

  if (!consumedAnyAmount || components.isEmpty) {
    return null;
  }

  return PreparedMealPendingIngredientFillResult(
    nextItems: nextItems,
    components: components,
    remainingIngredient: remainingAmount > 0
        ? ingredientParser.formatPendingIngredient(
            amount: remainingAmount,
            unit: requirement.unit,
            name: requirement.name,
          )
        : null,
  );
}

/// The open rows of [currentMeal] that the newly added amounts of
/// [components] do not fill yet, and [components] with each food that
/// fills exactly one of those rows linked to it, so the row opens again
/// when the food leaves the meal.
({List<String> rows, List<PreparedMealComponent> components})
reconciledPendingRecipeIngredients({
  required PreparedMeal currentMeal,
  required List<PreparedMealComponent> components,
}) {
  final pendingIngredients = currentMeal.pendingRecipeIngredients;
  final coverages = pendingIngredients.isEmpty
      ? const <_PendingIngredientCoverage>[]
      : _newComponentCoverages(
          previousComponents: currentMeal.components,
          components: components,
        );
  if (coverages.isEmpty) {
    return (rows: pendingIngredients, components: components);
  }

  final nextPendingIngredients = <String>[];
  for (final ingredient in pendingIngredients) {
    final requirement = _parsePendingRequirement(ingredient);
    final coverage = requirement == null
        ? null
        : _matchingCoverage(coverages: coverages, requirement: requirement);
    if (coverage == null) {
      nextPendingIngredients.add(ingredient);
      continue;
    }
    coverage.remainingAmount -= requirement!.amount;
    coverage.filledRows.add(ingredient);
  }
  // shortcut: a food that fills two rows stays unlinked and opens its own
  // amount and name; link a list of rows if that turns up.
  final rowByItemId = {
    for (final coverage in coverages)
      if (coverage.filledRows.length == 1)
        coverage.component.inventoryItemId: coverage.filledRows.single,
  };
  return (
    rows: nextPendingIngredients,
    components: [
      for (final component in components)
        if (component.pendingRecipeIngredient == null &&
            rowByItemId[component.inventoryItemId] != null)
          component.copyWith(
            pendingRecipeIngredient: rowByItemId[component.inventoryItemId],
          )
        else
          component,
    ],
  );
}

List<_PendingIngredientCoverage> _newComponentCoverages({
  required List<PreparedMealComponent> previousComponents,
  required List<PreparedMealComponent> components,
}) {
  final previousComponentsByItemId = {
    for (final component in previousComponents)
      component.inventoryItemId: component,
  };
  return components
      .map((component) {
        final previousComponent =
            previousComponentsByItemId[component.inventoryItemId];
        final previousAmount = previousComponent?.usedUnit == component.usedUnit
            ? previousComponent?.usedAmount ?? 0
            : 0;
        final remainingAmount = component.usedAmount - previousAmount;
        if (remainingAmount < 1) {
          return null;
        }
        return _PendingIngredientCoverage(
          component: component,
          remainingAmount: remainingAmount,
        );
      })
      .whereType<_PendingIngredientCoverage>()
      .toList(growable: false);
}

_PendingIngredientCoverage? _matchingCoverage({
  required List<_PendingIngredientCoverage> coverages,
  required TemplateIngredientRequirement requirement,
}) {
  for (final coverage in coverages) {
    if (_coverageSatisfiesRequirement(
      coverage: coverage,
      requirement: requirement,
    )) {
      return coverage;
    }
  }
  return null;
}

bool _coverageSatisfiesRequirement({
  required _PendingIngredientCoverage coverage,
  required TemplateIngredientRequirement requirement,
}) {
  final component = coverage.component;
  if (component.usedUnit != requirement.inventoryUnit ||
      coverage.remainingAmount < requirement.amount) {
    return false;
  }
  return ingredientMatchesFully(
    ingredient: requirement.name,
    item: component.sourceItemSnapshot,
  );
}

TemplateIngredientRequirement? _parsePendingRequirement(String ingredient) {
  return const TemplateIngredientParser().parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
}

class _PendingIngredientCoverage {
  new({required this.component, required this.remainingAmount});

  final PreparedMealComponent component;
  int remainingAmount;
  final filledRows = <String>[];
}
