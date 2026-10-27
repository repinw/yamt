import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_item_components.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rows.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

/// Builds edited prepared meal and reconciled inventory state.
///
/// A food that [inputs] leaves out only loses its place in the meal: its
/// row is open again, and its stock goes back to the Vorrat. The open or
/// ignored [deletedRows] leave the meal.
PreparedMealBuildResult buildPreparedMealEditResult({
  required PreparedMeal currentMeal,
  required List<InventoryItem> currentItems,
  required DateTime now,
  required String name,
  required bool imageChanged,
  required String? imageAssetId,
  required int totalPortions,
  required List<PreparedMealItemInput> inputs,
  List<String> deletedRows = const <String>[],
}) {
  final trimmedName = name.trim();
  final consumedPortions = _consumedPortions(currentMeal);
  final rowsMeal = currentMeal.withEditedRows(
    keptItemIds: {for (final input in inputs) input.itemId},
    deletedRows: deletedRows,
  );
  if (trimmedName.isEmpty ||
      totalPortions < 1 ||
      totalPortions < consumedPortions ||
      (inputs.isEmpty && rowsMeal.pendingRecipeIngredients.isEmpty)) {
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
  final reconciled = reconciledPendingRecipeIngredients(
    currentMeal: rowsMeal,
    components: components,
  );

  return PreparedMealBuildResult(
    nextItems: nextItems,
    preparedMeal: currentMeal.copyWith(
      name: trimmedName,
      imageAssetId: imageChanged
          ? normalizeOptionalImageAssetId(imageAssetId)
          : currentMeal.imageAssetId,
      totalPortions: totalPortions,
      remainingPortions: nextRemainingPortions,
      // A weighing counts grams per portion left; new portions void it.
      potWeighing: totalPortions == currentMeal.totalPortions
          ? currentMeal.potWeighing
          : null,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      pendingRecipeIngredients: reconciled.rows,
      ignoredPendingRecipeIngredients: rowsMeal.ignoredPendingRecipeIngredients,
      updatedAt: now,
      components: reconciled.components,
    ),
  );
}

/// The meal back as [previous] was before an edit, with the stock its foods
/// took then: the foods of [currentMeal] go back to the Vorrat and those of
/// [previous] are taken again. Portions eaten since stay eaten, the pot
/// stays as it is now, and the foods stay once a portion is gone.
PreparedMealBuildResult buildPreparedMealRestoreResult({
  required PreparedMeal currentMeal,
  required PreparedMeal previous,
  required List<InventoryItem> currentItems,
  required DateTime now,
}) {
  final remainingPortions =
      previous.totalPortions - _consumedPortions(currentMeal);
  if (remainingPortions <= 0) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }
  final restored = previous.copyWith(
    remainingPortions: remainingPortions,
    // The edit does not change the pot; a change since then stays.
    inPot: currentMeal.inPot,
    potTareWeight: currentMeal.potTareWeight,
    updatedAt: now,
  );
  final sameFoods = const ListEquality<PreparedMealComponent>().equals(
    previous.components,
    currentMeal.components,
  );
  if (previous.totalPortions == currentMeal.totalPortions && sameFoods) {
    // Only the name, the picture or the rows changed; the stock stays.
    return PreparedMealBuildResult(
      nextItems: currentItems,
      preparedMeal: restored,
    );
  }
  if (!sameFoods && !currentMeal.allows(PreparedMealAction.editIngredients)) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }

  final nextItems = restoreItemsFromPreparedMeal(
    currentItems: currentItems,
    meal: currentMeal,
  );
  for (final component in previous.components) {
    _reserveInventoryAmount(
      nextItems: nextItems,
      item: _findInventoryItem(nextItems, component.inventoryItemId),
      itemId: component.inventoryItemId,
      amount: remainingPreparedMealShareAmount(
        usedAmount: component.usedAmount,
        totalPortions: previous.totalPortions,
        remainingPortions: remainingPortions,
      ),
    );
  }
  return PreparedMealBuildResult(nextItems: nextItems, preparedMeal: restored);
}

List<PreparedMealComponent> _buildEditedComponents({
  required List<InventoryItem> nextItems,
  required Map<String, List<PreparedMealComponent>> existingComponents,
  required List<PreparedMealItemInput> inputs,
  required int totalPortions,
  required num remainingPortions,
}) {
  final seenItemIds = <String>{};
  return [
    for (final input in inputs)
      ..._buildEditedComponent(
        nextItems: nextItems,
        existing: existingComponents[input.itemId],
        input: input,
        seenItemIds: seenItemIds,
        totalPortions: totalPortions,
        remainingPortions: remainingPortions,
      ),
  ];
}

/// The components of one food of [input]: those the meal had for its item,
/// scaled together, or a new one.
List<PreparedMealComponent> _buildEditedComponent({
  required List<InventoryItem> nextItems,
  required List<PreparedMealComponent>? existing,
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

  if (existing != null && input.manualNutrition == null) {
    return scaledItemComponents(existing, input.usedAmount);
  }
  final sourceItem = inventoryItem;
  if (sourceItem == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.itemUnavailable,
    );
  }
  // A food with its own values keeps the row it filled, so the row opens
  // again when the food leaves the meal.
  final rows = {
    for (final component in existing ?? const <PreparedMealComponent>[])
      component.pendingRecipeIngredient,
  };
  return [
    _buildNewComponent(
      sourceItem: sourceItem,
      input: input,
    ).copyWith(pendingRecipeIngredient: rows.length == 1 ? rows.single : null),
  ];
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
  if (item == null || amount > item.availableAmount) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.insufficientAmount,
    );
  }

  final itemIndex = nextItems.indexWhere((entry) => entry.id == itemId);
  final nextItem = item.reducedBy(amount);
  if (itemIndex < 0 || nextItem == null) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.insufficientAmount,
    );
  }
  nextItems[itemIndex] = nextItem;
}

Map<String, List<PreparedMealComponent>> _componentLookup(
  List<PreparedMealComponent> components,
) => components.groupListsBy((component) => component.inventoryItemId);

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
