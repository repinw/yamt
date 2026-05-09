import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Builds edited prepared meal and reconciled inventory state.
PreparedMealBuildResult buildPreparedMealEditResult({
  required PreparedMeal currentMeal,
  required List<InventoryItem> currentItems,
  required DateTime now,
  required String name,
  required bool imageChanged,
  required String? imageAssetId,
  required int totalPortions,
  required List<PreparedMealItemInput> inputs,
}) {
  final trimmedName = name.trim();
  final consumedPortions = _consumedPortions(currentMeal);
  if (trimmedName.isEmpty ||
      totalPortions < 1 ||
      totalPortions < consumedPortions ||
      inputs.isEmpty) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }

  final nextRemainingPortions = totalPortions - consumedPortions;
  final nextItems = restoreItemsFromPreparedMeal(
    currentItems: currentItems,
    meal: currentMeal,
  );
  final existingComponents = _componentLookup(currentMeal.components);
  final components = _buildEditedComponents(
    nextItems: nextItems,
    existingComponents: existingComponents,
    inputs: inputs,
    totalPortions: totalPortions,
    remainingPortions: nextRemainingPortions,
  );
  final nutritionTotals = components.nutritionTotals;

  return PreparedMealBuildResult(
    nextItems: nextItems,
    preparedMeal: currentMeal.copyWith(
      name: trimmedName,
      imageAssetId: imageChanged
          ? normalizeOptionalImageAssetId(imageAssetId)
          : currentMeal.imageAssetId,
      totalPortions: totalPortions,
      remainingPortions: nextRemainingPortions,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      pendingRecipeIngredients: _reconciledPendingRecipeIngredients(
        currentMeal: currentMeal,
        components: components,
      ),
      updatedAt: now,
      components: components,
    ),
  );
}

List<PreparedMealComponent> _buildEditedComponents({
  required List<InventoryItem> nextItems,
  required Map<String, PreparedMealComponent> existingComponents,
  required List<PreparedMealItemInput> inputs,
  required int totalPortions,
  required num remainingPortions,
}) {
  final seenItemIds = <String>{};
  return [
    for (final input in inputs)
      _buildEditedComponent(
        nextItems: nextItems,
        existingComponent: existingComponents[input.itemId],
        input: input,
        seenItemIds: seenItemIds,
        totalPortions: totalPortions,
        remainingPortions: remainingPortions,
      ),
  ];
}

PreparedMealComponent _buildEditedComponent({
  required List<InventoryItem> nextItems,
  required PreparedMealComponent? existingComponent,
  required PreparedMealItemInput input,
  required Set<String> seenItemIds,
  required int totalPortions,
  required num remainingPortions,
}) {
  if (input.usedAmount < 1 || !seenItemIds.add(input.itemId)) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }

  final inventoryItem = _findInventoryItem(nextItems, input.itemId);
  final amountToReserve = remainingPreparedMealShareAmount(
    usedAmount: input.usedAmount,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
  );
  _reserveInventoryAmount(
    nextItems: nextItems,
    item: inventoryItem,
    itemId: input.itemId,
    amount: amountToReserve,
  );

  if (existingComponent != null && input.manualNutrition == null) {
    return _scaleExistingComponent(existingComponent, input.usedAmount);
  }
  final sourceItem = inventoryItem;
  if (sourceItem == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.itemUnavailable,
    );
  }
  return _buildNewComponent(sourceItem: sourceItem, input: input);
}

PreparedMealComponent _buildNewComponent({
  required InventoryItem sourceItem,
  required PreparedMealItemInput input,
}) {
  final resolvedNutrition = input.manualNutrition ?? sourceItem.nutrition;
  if (!hasCompleteNutrition(resolvedNutrition)) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.missingNutrition,
    );
  }

  final sourceItemSnapshot = input.manualNutrition == null
      ? sourceItem
      : sourceItem.copyWith(nutrition: input.manualNutrition);
  return buildPreparedMealComponent(
    item: sourceItemSnapshot,
    usedAmount: input.usedAmount,
    usedUnit: resolveUsedUnit(sourceItemSnapshot),
    nutrition: resolvedNutrition!,
  );
}

void _reserveInventoryAmount({
  required List<InventoryItem> nextItems,
  required InventoryItem? item,
  required String itemId,
  required int amount,
}) {
  if (amount < 1) {
    return;
  }
  if (item == null || amount > availableAmount(item)) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.insufficientAmount,
    );
  }

  final itemIndex = nextItems.indexWhere((entry) => entry.id == itemId);
  final nextItem = reduceInventoryItem(item: item, amount: amount);
  if (itemIndex < 0 || nextItem == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.insufficientAmount,
    );
  }
  nextItems[itemIndex] = nextItem;
}

PreparedMealComponent _scaleExistingComponent(
  PreparedMealComponent component,
  int usedAmount,
) {
  if (component.usedAmount < 1) {
    return component.copyWith(usedAmount: usedAmount);
  }
  final multiplier = usedAmount / component.usedAmount;
  return component.copyWith(
    usedAmount: usedAmount,
    totalKcal: component.totalKcal * multiplier,
    totalProtein: component.totalProtein * multiplier,
    totalCarbs: component.totalCarbs * multiplier,
    totalFat: component.totalFat * multiplier,
  );
}

Map<String, PreparedMealComponent> _componentLookup(
  List<PreparedMealComponent> components,
) {
  return {
    for (final component in components) component.inventoryItemId: component,
  };
}

InventoryItem? _findInventoryItem(List<InventoryItem> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) {
      return item;
    }
  }
  return null;
}

num _consumedPortions(PreparedMeal meal) {
  final consumed = meal.totalPortions - meal.remainingPortions;
  return consumed < 0 ? 0 : consumed;
}

List<String> _reconciledPendingRecipeIngredients({
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
  final previousComponentsByItemId = _componentLookup(previousComponents);
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
  if (component.usedUnit != requirement.unit ||
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
  _PendingIngredientCoverage({
    required this.component,
    required this.remainingAmount,
  });

  final PreparedMealComponent component;
  int remainingAmount;
}
