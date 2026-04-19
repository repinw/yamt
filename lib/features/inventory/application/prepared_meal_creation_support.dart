import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Builds a prepared meal from explicit inventory item inputs.
PreparedMealBuildResult buildPreparedMealCreationResult({
  required List<InventoryItem> currentItems,
  required String preparedMealId,
  required DateTime now,
  required String name,
  required String? imageAssetId,
  required int totalPortions,
  required List<PreparedMealItemInput> inputs,
}) {
  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];

  for (final input in inputs) {
    if (input.usedAmount < 1) {
      throw const PreparedMealBuildException(
        PreparedMealCreationFailureReason.invalidInput,
      );
    }

    final itemIndex = nextItems.indexWhere((item) => item.id == input.itemId);
    if (itemIndex < 0) {
      throw const PreparedMealBuildException(
        PreparedMealCreationFailureReason.itemUnavailable,
      );
    }

    final currentItem = nextItems[itemIndex];
    final remainingAmount = availableAmount(currentItem);
    if (input.usedAmount > remainingAmount) {
      throw const PreparedMealBuildException(
        PreparedMealCreationFailureReason.insufficientAmount,
      );
    }

    final resolvedNutrition = input.manualNutrition ?? currentItem.nutrition;
    if (!hasCompleteNutrition(resolvedNutrition)) {
      throw const PreparedMealBuildException(
        PreparedMealCreationFailureReason.missingNutrition,
      );
    }

    final sourceItemSnapshot = input.manualNutrition == null
        ? currentItem
        : currentItem.copyWith(nutrition: input.manualNutrition);
    final nextItem = reduceInventoryItem(
      item: sourceItemSnapshot,
      amount: input.usedAmount,
    );
    if (nextItem == null) {
      throw const PreparedMealBuildException(
        PreparedMealCreationFailureReason.insufficientAmount,
      );
    }

    nextItems[itemIndex] = nextItem;
    components.add(
      buildPreparedMealComponent(
        item: sourceItemSnapshot,
        usedAmount: input.usedAmount,
        usedUnit: resolveUsedUnit(currentItem),
        nutrition: resolvedNutrition!,
      ),
    );
  }

  final nutritionTotals = components.nutritionTotals;
  return PreparedMealBuildResult(
    nextItems: nextItems,
    preparedMeal: PreparedMeal(
      id: preparedMealId,
      name: name,
      imageAssetId: normalizeOptionalImageAssetId(imageAssetId),
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      createdAt: now,
      updatedAt: now,
      components: components,
    ),
  );
}
