import 'package:flutter/material.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart'
    as inventory_item_eat_sheet;
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart'
    as prepared_meal_dialogs;

/// Public diary-facing inventory quick-eat UI flow.
abstract final class InventoryQuickEatFlow {
  /// Shows the item eat sheet.
  static Future<InventoryItemEatRequest?> showItemSheet({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) {
    return inventory_item_eat_sheet.showInventoryItemEatSheet(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: invalidAmountMessage,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    );
  }

  /// Shows the prepared meal eat sheet.
  static Future<InventoryPreparedMealEatRequest?> showPreparedMealSheet({
    required BuildContext context,
    required PreparedMeal meal,
    bool useRootNavigator = false,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) async {
    final result = await prepared_meal_dialogs.showPreparedMealEatDialog(
      context,
      meal,
      useRootNavigator: useRootNavigator,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    );
    if (result == null) {
      return null;
    }
    return InventoryPreparedMealEatRequest(
      portions: result.portions,
      mealType: result.mealType,
      loggedDay: result.loggedDay,
    );
  }
}

/// Prepared meal eat request selected by the inventory quick-eat flow.
@immutable
class InventoryPreparedMealEatRequest {
  /// Creates a prepared meal eat request.
  const InventoryPreparedMealEatRequest({
    required this.portions,
    required this.mealType,
    required this.loggedDay,
  });

  /// Consumed portions.
  final num portions;

  /// Meal type for the calorie entry.
  final MealType mealType;

  /// Logged diary day.
  final DateTime loggedDay;
}
