import 'package:yamt/features/inventory/application/'
    'prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rows.dart';

/// Fills an open row of a meal with a chosen amount of one Vorrat item.
class PreparedMealPendingItemFill {
  /// Creates the workflows.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Uses [usedAmount] of the item [itemId] for the open or ignored row
  /// [ingredient] of the meal [mealId] and closes the row. Returns whether it
  /// worked.
  ///
  /// Unlike filling from the row's own amount, this works for rows without
  /// an amount ("Salz") and for foods found by search, whose amount the cook
  /// entered.
  Future<bool> fill({
    required String mealId,
    required String ingredient,
    required String itemId,
    required int usedAmount,
    required InventoryItemRepository inventoryRepository,
  }) async {
    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }
    final meal = currentMeals[mealIndex];
    final withoutRow = meal.withoutRow(ingredient);
    if (withoutRow == null) {
      return false;
    }

    final currentItems = await inventoryRepository.readAllForChange();
    final PreparedMealBuildResult built;
    try {
      built = buildPreparedMealCreationResult(
        currentItems: currentItems,
        preparedMealId: meal.id,
        now: _writer.buildNow(),
        name: meal.name,
        imageAssetId: meal.imageAssetId,
        totalPortions: meal.totalPortions,
        inputs: [PreparedMealItemInput(itemId: itemId, usedAmount: usedAmount)],
      );
    } on PreparedMealBuildException catch (error) {
      _writer.logMessage('Could not fill an open row: ${error.reason}.');
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = withoutRow.withComponents([
      ...meal.components,
      for (final component in built.preparedMeal.components)
        component.copyWith(pendingRecipeIngredient: ingredient.trim()),
    ], _writer.buildNow());
    return await _writer.saveMealsWithStock(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
      nextItems: built.nextItems,
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }
}
