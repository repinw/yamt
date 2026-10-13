import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rows.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Fills, ignores and opens the rows of a Vorrat meal, and takes foods out
/// of it again.
class PreparedMealOpenRows {
  /// Creates the open-row changes.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Fills the open or ignored row [ingredient] with the Vorrat items
  /// [inventoryItemIds]. When they cover only part of it, the rest stays in
  /// the row's place.
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
    if (mealIndex < 0 ||
        currentMeals[mealIndex].withoutRow(trimmedIngredient) == null) {
      return false;
    }

    final currentMeal = currentMeals[mealIndex];
    final currentItems = await inventoryRepository.readAllForChange();
    final fillResult = buildPreparedMealPendingIngredientFillResult(
      currentItems: currentItems,
      ingredient: trimmedIngredient,
      inventoryItemIds: normalizedItemIds,
      ingredientParser: ingredientParser,
    );
    if (fillResult == null) {
      return false;
    }

    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = currentMeal
        .withoutRow(trimmedIngredient, rest: fillResult.remainingIngredient)!
        .withComponents([
          ...currentMeal.components,
          ...fillResult.components,
        ], _writer.buildNow());
    return await _writer.saveMealsWithStock(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
      nextItems: fillResult.nextItems,
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }

  /// Ignores the open row [ingredient]: it stays on the meal, counts for
  /// nothing and can still be filled.
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) => _changeRow(mealId, (meal) => meal.withRowIgnored(ingredient));

  /// Opens the ignored row [ingredient] again.
  Future<bool> unignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) => _changeRow(mealId, (meal) => meal.withRowOpened(ingredient));

  /// Takes [component] out of the meal [mealId] again, the reverse of
  /// filling a row: the row it fills is open again, the totals are summed
  /// from the other foods, and its amount goes back to the Vorrat. Only
  /// while the meal's ingredients can change, so no portion is gone and the
  /// meal still holds all of the food.
  Future<bool> unassignPreparedMealComponent({
    required String mealId,
    required PreparedMealComponent component,
    required InventoryItemRepository inventoryRepository,
  }) async {
    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }
    final meal = currentMeals[mealIndex];
    final componentIndex = meal.components.indexOf(component);
    if (componentIndex < 0 ||
        !meal.allows(PreparedMealAction.editIngredients)) {
      return false;
    }

    final currentItems = await inventoryRepository.readAllForChange();
    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = meal
        .withComponents(
          [...meal.components]..removeAt(componentIndex),
          _writer.buildNow(),
        )
        .copyWith(
          pendingRecipeIngredients: [
            ...meal.pendingRecipeIngredients,
            component.openRow,
          ],
        );
    return await _writer.saveMealsWithStock(
      inventoryRepository: inventoryRepository,
      previousItems: currentItems,
      nextItems: restoreItemsFromPreparedMeal(
        currentItems: currentItems,
        meal: meal.copyWith(components: [component]),
      ),
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }

  /// Saves the meal [mealId] as [change] makes it; false when [change]
  /// finds no such row.
  Future<bool> _changeRow(
    String mealId,
    PreparedMeal? Function(PreparedMeal meal) change,
  ) async {
    final currentMeals = await _writer.loadMeals();
    final mealIndex = currentMeals.indexWhere((meal) => meal.id == mealId);
    if (mealIndex < 0) {
      return false;
    }
    final changed = change(currentMeals[mealIndex]);
    if (changed == null) {
      return false;
    }
    final nextMeals = List<PreparedMeal>.from(currentMeals);
    nextMeals[mealIndex] = changed.copyWith(updatedAt: _writer.buildNow());
    return await _writer.saveMeals(
      previousMeals: currentMeals,
      nextMeals: nextMeals,
    );
  }
}
