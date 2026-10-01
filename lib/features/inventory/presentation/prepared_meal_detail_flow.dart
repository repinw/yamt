import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';

/// Opens the detail page of a Vorrat meal: eat portions, fill or ignore its
/// open rows, edit it, and the other meal actions.
abstract final class PreparedMealDetailFlow {
  const new _();

  /// Opens the detail page of [meal].
  static Future<void> open({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
  }) async {
    await PreparedMealEatFlow.eat(
      context: context,
      meal: meal,
      actions: actions(context, ref),
    );
  }

  /// The meal actions of the detail page, backed by the Vorrat controllers.
  static PreparedMealActions actions(BuildContext context, WidgetRef ref) {
    const coordinator = InventoryPreparedMealEditCoordinator();
    final meals = ref.read(preparedMealsControllerProvider.notifier);
    return PreparedMealActions(
      throwAway: (mealId, portions, reason) => meals.throwAwayPreparedMeal(
        mealId: mealId,
        discardedPortions: portions,
        reason: reason,
      ),
      fillPendingIngredient: (mealId, ingredient, itemIds) =>
          meals.fillPreparedMealPendingIngredient(
            mealId: mealId,
            ingredient: ingredient,
            inventoryItemIds: itemIds,
          ),
      fillPendingIngredientWithItem: (mealId, ingredient, itemId, amount) =>
          meals.fillPreparedMealPendingIngredientWithItem(
            mealId: mealId,
            ingredient: ingredient,
            itemId: itemId,
            usedAmount: amount,
          ),
      ignorePendingIngredient: (mealId, ingredient) =>
          meals.ignorePreparedMealPendingIngredient(
            mealId: mealId,
            ingredient: ingredient,
          ),
      unbundle: meals.unbundlePreparedMeal,
      edit: (mealId, result, messenger) => coordinator.updatePreparedMeal(
        context: context,
        ref: ref,
        mealId: mealId,
        result: result,
        messenger: messenger,
      ),
      saveTemplate: (meal, messenger) => coordinator.saveTemplate(
        context: context,
        ref: ref,
        meal: meal,
        messenger: messenger,
      ),
    );
  }
}
