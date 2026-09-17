import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/domain/inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_eat_sheet.dart'
    as item_sheet;
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_action_dialogs.dart'
    as meal_dialogs;

/// Presentation implementation that opens inventory-owned picker sheets.
class InventoryQuickEatSheetPicker implements InventoryQuickEatPicker {
  /// Creates the inventory-owned quick-eat sheet picker.
  const new();

  @override
  Future<InventoryItemEatRequest?> pickItem({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) => item_sheet.showInventoryItemEatSheet(
    context: context,
    item: item,
    maxAmount: maxAmount,
    invalidAmountMessage: invalidAmountMessage,
    initialInventoryAmount: initialInventoryAmount,
    initialLoggedAt: initialLoggedAt,
    initialMealType: initialMealType,
  );

  @override
  Future<InventoryItemEatSheetResult?> pickItemResult({
    required BuildContext context,
    required InventoryItem item,
    required int maxAmount,
    required String invalidAmountMessage,
    required InventoryItemEatSheetIntent confirmIntent,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    String? addMoreActionText,
  }) => item_sheet.showInventoryItemEatSheetResult(
    context: context,
    item: item,
    maxAmount: maxAmount,
    invalidAmountMessage: invalidAmountMessage,
    confirmIntent: confirmIntent,
    initialInventoryAmount: initialInventoryAmount,
    initialLoggedAt: initialLoggedAt,
    initialMealType: initialMealType,
    addMoreActionText: addMoreActionText,
  );

  @override
  Future<InventoryPreparedMealEatRequest?> pickPreparedMeal({
    required BuildContext context,
    required PreparedMeal meal,
    required bool useRootNavigator,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) async {
    final result = await meal_dialogs.showPreparedMealEatDialog(
      context,
      meal,
      useRootNavigator: useRootNavigator,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    );
    return result == null
        ? null
        : InventoryPreparedMealEatRequest(
            portions: result.portions,
            mealType: result.mealType,
            loggedDay: result.loggedDay,
          );
  }
}
