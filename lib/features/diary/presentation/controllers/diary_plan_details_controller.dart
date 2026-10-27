import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_check_save_service.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_state.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';

part 'diary_plan_details_controller.g.dart';

/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.
@riverpod
class DiaryPlanDetailsController extends _$DiaryPlanDetailsController {
  @override
  DiaryPlanDetailsState? build(
    String planId,
    DateTime planDay,
    DateTime today,
  ) {
    final day = ref.watch(
      diaryDayDashboardControllerProvider(planDay).select(
        (state) => (
          isLoaded: state.data != null,
          plan: state.data?.plannedEntries.firstWhereOrNull(
            (entry) => entry.id == planId,
          ),
        ),
      ),
    );
    // A day that reloads without data keeps the page as it is.
    if (!day.isLoaded) {
      return stateOrNull;
    }
    final plan = day.plan;
    if (plan == null) {
      return null;
    }
    final mealId = plan.bundleSourcePreparedMealId;
    // A meal that left the Vorrat hides the counter.
    final meal = mealId == null
        ? null
        : ref.watch(livePreparedMealProvider(mealId)).value;
    final now = ref.watch(clockProvider)();
    // The picks stay when the plan or its meal changes.
    final previous = stateOrNull;
    final previousText = previous?.amount.amountText;
    final next = DiaryPlanDetailsState(
      // The plan as stored now. An amount the user did not type follows it.
      amount: DiaryEntryDetailsState(
        entry: plan,
        amountText:
            previousText == null ||
                previousText ==
                    diaryEntryAmountText(previous!.plan.consumedAmount)
            ? diaryEntryAmountText(plan.consumedAmount)
            : previousText,
        today: today,
      ),
      // A day or meal the user did not pick follows the plan.
      loggedAt: previous == null || previous.loggedAt == previous.plan.loggedAt
          ? plan.loggedAt
          : previous.loggedAt,
      mealType: previous == null || previous.mealType == previous.plan.mealType
          ? plan.mealType
          : previous.mealType,
      now: previous?.now ?? now,
      meal: meal,
      pickedPortions: previous?.pickedPortions,
    );
    // A pick above what the meal has left now drops to it for good.
    return previous?.pickedPortions == null
        ? next
        : next.copyWith(pickedPortions: next.portions);
  }

  /// Takes a typed amount.
  void setAmountText(String text) {
    _update(
      (current) =>
          current.copyWith(amount: current.amount.copyWith(amountText: text)),
    );
  }

  /// Takes a picked day; the plan keeps its time of day.
  void setDay(DateTime day) {
    _update((current) {
      final time = current.loggedAt;
      return current.copyWith(
        loggedAt: DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
        ),
      );
    });
  }

  /// Takes a picked meal.
  void setMealType(MealType mealType) {
    _update((current) => current.copyWith(mealType: mealType));
  }

  /// Takes picked portions of the cooked meal.
  void setPortions(int portions) {
    _update((current) => current.copyWith(pickedPortions: portions));
  }

  /// Saves [itemId] as the Vorrat item of [ingredient] on the recipe
  /// [templateId], so its next cooking and the plans of the recipe without
  /// choices of their own take it, and plans this plan anew from it.
  /// False when the recipe is gone or the save failed.
  Future<bool> pickIngredientItem(
    String templateId,
    String ingredient,
    String itemId,
  ) async {
    final link = ref.keepAlive();
    // Held for the write, so the workflow and its store stay alive.
    final workflow = ref.listen(ingredientCheckSaveServiceProvider, (_, _) {});
    final templates = ref.listen(planTemplatesProvider.future, (_, _) {});
    final items = ref.listen(inventoryQuickEatItemsProvider.future, (_, _) {});
    final plans = ref.listen(
      preparedMealReminderPlanServiceProvider,
      (_, _) {},
    );
    try {
      // The recipe as saved now, so a change made meanwhile stays.
      final recipe = (await templates.read()).firstWhereOrNull(
        (template) => template.id == templateId,
      );
      if (recipe == null) {
        return false;
      }
      final assignments = {
        ...recipe.recipeIngredientAssignments,
        ingredient: [itemId],
      };
      await workflow.read().save(
        recipe: recipe,
        assignments: assignments,
        ignored: recipe.ignoredRecipeIngredients,
        onList: const [],
        onRecipeSaved: () {},
      );
      // Other plans that hold the cook's own choices keep them; this one
      // follows the pick made on it.
      await plans.read().replanRecipePlan(
        planId,
        recipe.copyWith(recipeIngredientAssignments: assignments),
        await items.read(),
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Saving the Vorrat item of a recipe line failed.',
        name: 'DiaryPlanDetailsController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      plans.close();
      items.close();
      templates.close();
      workflow.close();
      link.close();
    }
  }

  void _update(
    DiaryPlanDetailsState Function(DiaryPlanDetailsState current) change,
  ) {
    if (state case final current?) {
      state = change(current);
    }
  }
}
