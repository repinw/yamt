import 'dart:developer' as developer;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';

/// Eats portions of a prepared meal and logs them as one calorie entry.
abstract final class PreparedMealEatFlow {
  const new _();

  /// Opens the eat sheet for [meal] and logs the entered portions.
  ///
  /// Returns the saved entry, or null when the user cancels or saving fails.
  static Future<CalorieEntry?> eat({
    required BuildContext context,
    required PreparedMeal meal,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) async {
    final request = await showPreparedMealEatSheet(
      context,
      meal,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    );
    if (request == null || !context.mounted) {
      return null;
    }
    return await runInventoryQuickEatFlow(context, (scope) async {
      try {
        final entry = await scope.actions.consumePreparedMeal(
          meal: meal,
          consumedPortions: request.portions,
          mealType: request.mealType,
          loggedDay: request.loggedDay,
        );
        if (entry == null) {
          scope.messenger.showAppSnackBar(
            scope.l10n.preparedMealActionFailed,
            tone: AppSnackBarTone.error,
          );
          return null;
        }
        scope.messenger.showAppSnackBar(
          scope.l10n.inventoryManualAddEatSucceeded,
          onUndo: () => InventoryCalorieBridgeFlow.undoEat(
            container: scope.container,
            entry: entry,
          ),
        );
        return entry;
      } on Object catch (error, stackTrace) {
        developer.log(
          'Prepared meal eat flow failed.',
          name: 'PreparedMealEatFlow',
          error: error,
          stackTrace: stackTrace,
        );
        scope.messenger.showAppSnackBar(
          scope.l10n.preparedMealActionFailed,
          tone: AppSnackBarTone.error,
        );
        return null;
      }
    });
  }
}
