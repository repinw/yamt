import 'package:yamt/features/inventory/application/'
    'prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Fills an open row of a meal with a chosen amount of one Vorrat item.
class PreparedMealPendingItemFill {
  /// Creates the workflows.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Uses [usedAmount] of the item [itemId] for the open row [ingredient] of
  /// the meal [mealId] and closes the row. Returns whether it worked.
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
    final pendingIndex = meal.pendingRecipeIngredients.indexWhere(
      (entry) => entry.trim() == ingredient.trim(),
    );
    if (pendingIndex < 0) {
      return false;
    }

    final currentItems = await inventoryRepository.readAll();
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

    if (!await inventoryRepository.saveAll(built.nextItems)) {
      return false;
    }

    final components = <PreparedMealComponent>[
      ...meal.components,
      ...built.preparedMeal.components,
    ];
    final totals = components.nutritionTotals;
    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = meal.copyWith(
      components: components,
      pendingRecipeIngredients: [...meal.pendingRecipeIngredients]
        ..removeAt(pendingIndex),
      totalKcal: totals.totalKcal,
      totalProtein: totals.totalProtein,
      totalCarbs: totals.totalCarbs,
      totalFat: totals.totalFat,
      updatedAt: _writer.buildNow(),
    );
    if (await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    )) {
      return true;
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return false;
  }
}
