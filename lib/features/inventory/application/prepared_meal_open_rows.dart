import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Fills or leaves out the open rows of a Vorrat meal.
class PreparedMealOpenRows {
  /// Creates the open-row changes.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Fills one pending template ingredient with inventory.
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
    required InventoryItemRepository inventoryRepository,
    required TemplateIngredientParser ingredientParser,
  }) async {
    final trimmedIngredient = ingredient.trim();
    final normalizedItemIds = inventoryItemIds
        .map((itemId) => itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toList(growable: false);
    if (trimmedIngredient.isEmpty || normalizedItemIds.isEmpty) {
      return false;
    }

    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final pendingIndex = currentMeal.pendingRecipeIngredients.indexWhere(
      (entry) => entry.trim() == trimmedIngredient,
    );
    if (pendingIndex < 0) {
      return false;
    }

    final currentItems = await inventoryRepository.readAll();
    final fillResult = buildPreparedMealPendingIngredientFillResult(
      currentItems: currentItems,
      ingredient: trimmedIngredient,
      inventoryItemIds: normalizedItemIds,
      ingredientParser: ingredientParser,
    );
    if (fillResult == null) {
      return false;
    }

    final inventorySaved = await inventoryRepository.saveAll(
      fillResult.nextItems,
    );
    if (!inventorySaved) {
      return false;
    }

    final nextPendingIngredients = List<String>.from(
      currentMeal.pendingRecipeIngredients,
    )..removeAt(pendingIndex);
    if (fillResult.remainingIngredient != null) {
      nextPendingIngredients.insert(
        pendingIndex,
        fillResult.remainingIngredient!,
      );
    }

    final nextComponents = <PreparedMealComponent>[
      ...currentMeal.components,
      ...fillResult.components,
    ];
    final nutritionTotals = nextComponents.nutritionTotals;
    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = currentMeal.copyWith(
      components: nextComponents,
      pendingRecipeIngredients: nextPendingIngredients,
      totalKcal: nutritionTotals.totalKcal,
      totalProtein: nutritionTotals.totalProtein,
      totalCarbs: nutritionTotals.totalCarbs,
      totalFat: nutritionTotals.totalFat,
      updatedAt: _writer.buildNow(),
    );

    final mealsSaved = await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
    if (mealsSaved) {
      return true;
    }

    await _writer.restoreInventory(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
    );
    return false;
  }

  /// Marks one pending ingredient as intentionally ignored.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) async {
    final trimmedIngredient = ingredient.trim();
    if (trimmedIngredient.isEmpty) {
      return false;
    }

    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final nextPendingIngredients = currentMeal.pendingRecipeIngredients
        .where((entry) => entry.trim() != trimmedIngredient)
        .toList(growable: false);
    if (nextPendingIngredients.length ==
        currentMeal.pendingRecipeIngredients.length) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = currentMeal.copyWith(
      pendingRecipeIngredients: nextPendingIngredients,
      updatedAt: _writer.buildNow(),
    );
    return await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }
}
