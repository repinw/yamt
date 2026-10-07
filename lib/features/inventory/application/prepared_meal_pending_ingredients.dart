import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Consumes inventory to fill one pending template ingredient entry.
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
    return null;
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
    if (!hasCompatibleTemplateRequirement(
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
      ),
    );
    remainingAmount = remainingRequirementAfterConsumption(
      item: currentItem,
      requiredUnit: requiredUnit,
      remainingAmount: remainingAmount,
      consumedAmount: consumableAmount,
    );
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

/// The best Vorrat item that can fill the open row [ingredient] with the
/// row's own amount, or `null` when the row has no amount or no matching
/// item supplies its unit. It uses the same unit check as
/// [buildPreparedMealPendingIngredientFillResult].
InventoryItem? findPendingIngredientStockMatch({
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  required TemplateIngredientParser ingredientParser,
  required String localeCode,
}) {
  final requirement = ingredientParser.parseRequirement(
    ingredient: ingredient,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (requirement == null) {
    return null;
  }
  return matchInventoryItemsForIngredient(
    ingredient: ingredient,
    inventoryItems: inventoryItems,
    localeCode: localeCode,
  ).firstWhereOrNull(
    (item) => hasCompatibleTemplateRequirement(
      item: item,
      requiredUnit: requirement.inventoryUnit,
    ),
  );
}

/// The open rows of [currentMeal] that the newly added amounts of
/// [components] do not fill yet.
List<String> reconciledPendingRecipeIngredients({
  required PreparedMeal currentMeal,
  required List<PreparedMealComponent> components,
}) {
  final pendingIngredients = currentMeal.pendingRecipeIngredients;
  if (pendingIngredients.isEmpty) {
    return pendingIngredients;
  }

  final coverages = _newComponentCoverages(
    previousComponents: currentMeal.components,
    components: components,
  );
  if (coverages.isEmpty) {
    return pendingIngredients;
  }

  final nextPendingIngredients = <String>[];
  for (final ingredient in pendingIngredients) {
    final requirement = _parsePendingRequirement(ingredient);
    if (requirement == null) {
      nextPendingIngredients.add(ingredient);
      continue;
    }

    final coverage = _matchingCoverage(
      coverages: coverages,
      requirement: requirement,
    );
    if (coverage == null) {
      nextPendingIngredients.add(ingredient);
      continue;
    }
    coverage.remainingAmount -= requirement.amount;
  }
  return nextPendingIngredients;
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
  return ingredientInventoryMatchScore(
        ingredient: requirement.name,
        item: component.sourceItemSnapshot,
      ) >
      0;
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
}
