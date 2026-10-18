import 'dart:developer' show log;

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_transcript.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_ingredient_texts.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/inventory/application/prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

part 'recipe_controller.g.dart';

/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.
@riverpod
class RecipeController extends _$RecipeController {
  @override
  RecipeDraft build(String recipeId) => const RecipeDraft();

  /// Cooks [portions] portions.
  void setPortions(int portions) {
    if (portions >= 1) {
      state = state.copyWith(portions: portions);
    }
  }

  /// Takes the ingredient of the line [key] from the Vorrat item [itemId],
  /// or not from the Vorrat when it is `null`.
  void pick(String key, String? itemId) {
    state = state.copyWith(picks: {...state.picks, key: itemId});
  }

  /// Adds the ingredients in [transcript], said or typed for the chosen
  /// portions of [view], for this cooking. An undo word such as "nein" at
  /// its start takes the ones added last out again first.
  void addSpoken(RecipeView view, String transcript) {
    var text = transcript;
    if (afterUndoWords(transcript) case final rest?) {
      undoAdded();
      text = rest;
    }
    final parser = ref.read(templateIngredientParserProvider);
    var edits = state.edits;
    final keys = <String>[];
    for (final row in splitFreeCookingTranscript(text)) {
      keys.add(edits.nextKey);
      edits = edits.withAdded(recipeAddedText(parser, view, row));
    }
    if (keys.isNotEmpty) {
      state = state.copyWith(
        edits: edits,
        justAdded: keys,
        fromGuide: [...state.fromGuide, ...keys],
      );
    }
  }

  /// Takes the ingredients added last out again.
  void undoAdded() => _dropAdded(state.justAdded.toSet());

  /// Takes every ingredient the Kochhelfer added out again.
  void undoGuideAdded() => _dropAdded(state.fromGuide.toSet());

  void _dropAdded(Set<String> remove) {
    if (remove.isEmpty) {
      return;
    }
    final edits = state.edits;
    state = state.copyWith(
      edits: edits.copyWith(
        added: {
          for (final MapEntry(:key, :value) in edits.added.entries)
            if (!remove.contains(key)) key: value,
        },
      ),
      picks: {
        for (final MapEntry(:key, :value) in state.picks.entries)
          if (!remove.contains(key)) key: value,
      },
      justAdded: const <String>[],
      fromGuide: [
        for (final key in state.fromGuide)
          if (!remove.contains(key)) key,
      ],
    );
  }

  /// Opens the Kochhelfer before cooking when [withGuide] is set.
  void setWithGuide({required bool withGuide}) {
    state = state.copyWith(withGuide: withGuide);
  }

  /// Cooks the recipe with [edits] this time.
  void setEdits(RecipeEdits edits) {
    state = state.copyWith(
      edits: edits,
      justAdded: const <String>[],
      // A line changed by hand is the cook's own now, not the Kochhelfer's.
      fromGuide: [
        for (final key in state.fromGuide)
          if (edits.added[key] case final text?
              when text == state.edits.added[key])
            key,
      ],
    );
  }

  /// Drops the picks for the lines [keys], so the items the recipe saved
  /// for them apply again.
  void forgetPicks(Iterable<String> keys) {
    final remove = keys.toSet();
    state = state.copyWith(
      picks: {
        for (final MapEntry(:key, :value) in state.picks.entries)
          if (!remove.contains(key)) key: value,
      },
    );
  }

  /// Puts the meal of [view] in the pot. Returns its id, or `null` when
  /// saving failed.
  Future<String?> cook(RecipeView view) async {
    if (state.isCooking) {
      return null;
    }
    final link = ref.keepAlive();
    state = state.copyWith(isCooking: true);
    try {
      final result = await ref
          .read(preparedMealCookingServiceProvider)
          .cookRecipe(
            recipe: view.recipe.copyWith(totalPortions: view.basePortions),
            portions: view.portions,
            assignments: view.assignments,
          );
      return result.isSuccess ? result.preparedMealId : null;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to cook the recipe.',
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

  /// Plans one portion of [view], cooked as the page shows it now, on [day]
  /// for the meal of the current time. Returns the plan, or `null` when
  /// there is nothing to plan or saving failed.
  Future<CalorieEntry?> plan(RecipeView view, DateTime day) async {
    final link = ref.keepAlive();
    try {
      final now = ref.read(clockProvider);
      final plan = buildTemplatePlanEntry(
        template: view.recipe.copyWith(totalPortions: view.basePortions),
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
  // Cooking and the Kochhelfer switch leave the view as it is.
  final (:portions, :picks, :edits) = ref.watch(
    recipeControllerProvider(recipeId).select(
      (draft) =>
          (portions: draft.portions, picks: draft.picks, edits: draft.edits),
    ),
  );
  return buildRecipeView(
    recipeId: recipeId,
    templates: ref.watch(cookbookTemplatesProvider),
    items: ref.watch(inventoryQuickEatItemsProvider),
    parser: ref.watch(templateIngredientParserProvider),
    localeCode: localeCode,
    portions: portions,
    picks: picks,
    edits: edits,
  );
}
