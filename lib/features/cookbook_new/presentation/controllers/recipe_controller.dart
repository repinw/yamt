import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/vorlage_as_recipe.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/inventory/application/prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

part 'recipe_controller.g.dart';

/// Holds the portions of the recipe [recipeId], cooks a Vorlage, and plans
/// it.
@riverpod
class RecipeController extends _$RecipeController {
  /// The [RecipeIngredientLines.recipeEstimateKey]s estimated while the page
  /// is open.
  final Set<String> _estimated = {};

  @override
  RecipeDraft build(String recipeId) => const RecipeDraft();

  /// Estimates the nutrition and line weights of the saved recipe in the
  /// background, such as after a link import saved it.
  void estimate() =>
      ref.read(recipeEstimateServiceProvider).estimateInBackground(recipeId);

  /// Estimates [recipe] in the background when it has ingredient lines that
  /// its estimate does not fit, such as a recipe the AI chef, the editor, or
  /// "Ins Kochbuch" saved, once for each version of its lines and portions;
  /// an estimate that runs already is joined. One that ends without an
  /// estimate goes into [RecipeDraft.failedEstimates], so the page stops
  /// waiting for it; the cook is not told more.
  void estimateIfMissing(PreparedMeal recipe) {
    final key = recipe.recipeEstimateKey;
    if (recipe.needsRecipeEstimate && _estimated.add(key)) {
      unawaited(_estimate(key));
    }
  }

  Future<void> _estimate(String key) async {
    var fits = false;
    try {
      // Inside the future: the page asks while it builds, and a service that
      // fails at once must not change the state then.
      fits = await Future(
        () => ref.read(recipeEstimateServiceProvider).estimate(recipeId),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Estimating the recipe $recipeId failed.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!fits && ref.mounted) {
      state = state.copyWith(failedEstimates: {...state.failedEstimates, key});
    }
  }

  /// Cooks [portions] portions.
  void setPortions(int portions) {
    if (portions >= 1) {
      state = state.copyWith(portions: portions);
    }
  }

  /// Puts the Vorlage of [view] in the pot. Returns the meal's id, or
  /// `null` when saving failed.
  Future<String?> cook(RecipeView view) async {
    if (state.isCooking) {
      return null;
    }
    final link = ref.keepAlive();
    state = state.copyWith(isCooking: true);
    try {
      final result = await ref
          .read(preparedMealCookingServiceProvider)
          .cookVorlage(
            vorlage: view.saved,
            portions: view.portions,
            foods: _vorlageFoods(view),
          );
      return result.isSuccess ? result.preparedMealId : null;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to cook the Vorlage.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isCooking: false);
      }
      link.close();
    }
  }

  /// The foods of the Vorlage of [view] for its portions, from the items
  /// the page shows for them.
  List<VorlageFood> _vorlageFoods(RecipeView view) {
    final assignments = view.assignments;
    return [
      for (final (:line, :food) in vorlageFoods(
        view.saved,
        ref.read(templateIngredientParserProvider),
      ))
        (
          name: food.name,
          unit: food.unit,
          amount: food.amount * view.portions / view.basePortions,
          itemIds: assignments[line] ?? const <String>[],
        ),
    ];
  }

  /// Plans one portion of [view], cooked as the page shows it now, on [day]
  /// for the meal of the current time. Returns the plan, or `null` when
  /// there is nothing to plan or saving failed.
  Future<CalorieEntry?> plan(RecipeView view, DateTime day) async {
    final link = ref.keepAlive();
    try {
      final now = ref.read(clockProvider);
      final plan = buildTemplatePlanEntry(
        // A Vorlage plans with its own values, as meal planning counts it.
        template: view.isVorlage
            ? view.saved
            : view.recipe.copyWith(totalPortions: view.basePortions),
        cookedPortions: view.portions,
        assignments: view.assignments,
        items: ref.read(inventoryQuickEatItemsProvider).value ?? const [],
        parser: ref.read(templateIngredientParserProvider),
        mealType: MealType.defaultForDateTime(now()),
        loggedDay: day,
        now: now,
        nextEntryId: const Uuid().v4,
      );
      if (plan == null) {
        return null;
      }
      await ref.read(calorieDayLogServiceProvider).plan(plan);
      return plan;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to plan the recipe.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      link.close();
    }
  }

  /// The missing ingredients of the saved [plan] that the shopping list does
  /// not hold yet; none when they cannot be told.
  Future<List<ShoppingPlanNeed>> missingIngredients(CalorieEntry plan) async {
    final link = ref.keepAlive();
    try {
      return await missingPlanIngredients(ref, plan);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to find the missing ingredients of the plan.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    } finally {
      link.close();
    }
  }

  /// Deletes the saved recipe [plan] again. Returns whether it worked.
  Future<bool> unplan(CalorieEntry plan) async {
    final link = ref.keepAlive();
    try {
      await ref.read(calorieDayLogServiceProvider).deletePlans([plan]);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to remove the recipe plan.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      link.close();
    }
  }
}

/// The recipe [recipeId] with its ingredients for the chosen portions and
/// their Vorrat items, or `null` when the recipe is gone; see
/// [buildRecipeView].
@riverpod
AsyncValue<RecipeView?> recipeView(
  Ref ref,
  String recipeId,
  String localeCode,
) {
  // Cooking leaves the view as it is.
  final portions = ref.watch(
    recipeControllerProvider(recipeId).select((draft) => draft.portions),
  );
  return buildRecipeView(
    recipeId: recipeId,
    templates: ref.watch(cookbookTemplatesProvider),
    items: ref.watch(inventoryQuickEatItemsProvider),
    parser: ref.watch(templateIngredientParserProvider),
    localeCode: localeCode,
    portions: portions,
    // A running cook run keeps the portions it started with.
    runPortions: ref.watch(recipeCookRunProvider(recipeId)).value?.portions,
  );
}
