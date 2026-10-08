import 'dart:developer' as developer;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';

/// Eats portions of a prepared meal and logs them as one calorie entry.
abstract final class PreparedMealEatFlow {
  const new _();

  /// Opens the eat sheet for [meal] and logs the entered portions.
  ///
  /// With [actions] the sheet is the meal's detail page from the Vorrat: it
  /// also lists the ingredients and offers the meal actions.
  ///
  /// A day after today saves a plan and keeps the portions. Returns the
  /// saved entry or plan, or null when the user cancels or saving fails.
  static Future<CalorieEntry?> eat({
    required BuildContext context,
    required PreparedMeal meal,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    PreparedMealActions? actions,
  }) async {
    final request = await showPreparedMealEatSheet(
      context,
      meal,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
      actions: actions,
    );
    if (request == null || !context.mounted) {
      return null;
    }
    return await runInventoryQuickEatFlow(context, (scope) async {
      try {
        final eaten = await scope.actions.consumePreparedMeal(
          meal: request.meal,
          consumedPortions: request.portions,
          mealType: request.mealType,
          loggedDay: request.loggedDay,
          asPlan: request.isPlan,
          potNetWeight: request.potNetWeight,
        );
        if (eaten == null) {
          scope.messenger.showAppSnackBar(
            scope.l10n.preparedMealActionFailed,
            tone: AppSnackBarTone.error,
          );
          return null;
        }
        final (:entry, :isPlan) = eaten;
        scope.messenger.showAppSnackBar(
          isPlan
              ? planSavedMessage(
                  scope.l10n,
                  day: entry.loggedAt,
                  today: scope.container.read(clockProvider)(),
                )
              : scope.l10n.inventoryManualAddEatSucceeded,
          onUndo: () => isPlan
              ? InventoryItemEatFlow.undoPlan(
                  container: scope.container,
                  plan: entry,
                )
              : InventoryItemEatFlow.undoEat(
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
