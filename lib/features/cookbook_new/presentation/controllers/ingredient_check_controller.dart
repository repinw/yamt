import 'dart:developer' show log;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';

part 'ingredient_check_controller.g.dart';

/// What the cook does with an ingredient, or with the part of it that the
/// Vorrat lacks.
enum IngredientCheckChoice {
  /// Take it from the Vorrat.
  use,

  /// Put it on the shopping list.
  cart,

  /// Take a food that "Hab ich" just added to the Vorrat.
  have,

  /// Leave it out of the recipe.
  ignore,
}

/// The cook's choices in the ingredient check.
@immutable
class IngredientCheckDraft {
  /// Creates the draft.
  const new({
    this.choices = const <String, IngredientCheckChoice>{},
    this.restChoices = const <String, IngredientCheckChoice>{},
    this.haveItems = const <String, String>{},
    this.addedItems = const <String>{},
    this.picks = const <String, String?>{},
    this.isSaving = false,
  });

  /// The choice per saved ingredient that the cook changed.
  final Map<String, IngredientCheckChoice> choices;

  /// The choice for the missing part of a partly stocked ingredient.
  final Map<String, IngredientCheckChoice> restChoices;

  /// The Vorrat item that "Hab ich" added per saved ingredient.
  final Map<String, String> haveItems;

  /// Every Vorrat item that "Hab ich" added in this check, also the ones a
  /// later "Hab ich" replaced.
  final Set<String> addedItems;

  /// The Vorrat item picked in the check per saved ingredient; `null` means
  /// "not from the Vorrat".
  final Map<String, String?> picks;

  /// Whether "Fertig" is saving the choices.
  final bool isSaving;

  /// The choice for [line]: a stocked ingredient starts from the Vorrat, a
  /// missing one on the shopping list.
  IngredientCheckChoice choiceOf(RecipeIngredientLine line) =>
      choices[line.ingredient] ??
      (line.items.isEmpty
          ? IngredientCheckChoice.cart
          : IngredientCheckChoice.use);

  /// The choice for the missing part of [line]; it starts on the list.
  IngredientCheckChoice restChoiceOf(RecipeIngredientLine line) =>
      restChoices[line.ingredient] ?? IngredientCheckChoice.cart;

  /// Returns a copy with the given values.
  IngredientCheckDraft copyWith({
    Map<String, IngredientCheckChoice>? choices,
    Map<String, IngredientCheckChoice>? restChoices,
    Map<String, String>? haveItems,
    Set<String>? addedItems,
    Map<String, String?>? picks,
    bool? isSaving,
  }) => IngredientCheckDraft(
    choices: choices ?? this.choices,
    restChoices: restChoices ?? this.restChoices,
    haveItems: haveItems ?? this.haveItems,
    addedItems: addedItems ?? this.addedItems,
    picks: picks ?? this.picks,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// How "Fertig" of the ingredient check ended.
enum IngredientCheckFinish {
  /// The recipe and the shopping list are saved.
  done,

  /// The recipe could not be saved; nothing changed.
  recipeFailed,

  /// The recipe is saved, but the shopping list could not be changed.
  listFailed,

  /// "Fertig" is still saving.
  busy,
}

/// Holds the choices of the ingredient check for one recipe and saves them
/// on the recipe.
@riverpod
class IngredientCheckController extends _$IngredientCheckController {
  @override
  IngredientCheckDraft build(String recipeId) => const IngredientCheckDraft();

  /// Sets what happens with [ingredient], or with its missing part when
  /// [rest] is set.
  void choose(
    String ingredient,
    IngredientCheckChoice choice, {
    bool rest = false,
  }) {
    state = rest
        ? state.copyWith(
            restChoices: {...state.restChoices, ingredient: choice},
          )
        : state.copyWith(choices: {...state.choices, ingredient: choice});
  }

  /// Takes [ingredient] from the Vorrat item [itemId], or not from the
  /// Vorrat when it is `null`. Its choices start over.
  void pick(String ingredient, String? itemId) {
    state = state.copyWith(
      picks: {...state.picks, ingredient: itemId},
      choices: {...state.choices}..remove(ingredient),
      restChoices: {...state.restChoices}..remove(ingredient),
    );
  }

  /// Takes [ingredient], or its missing part when [rest] is set, from the
  /// Vorrat item [itemId] that "Hab ich" added.
  void have(String ingredient, String itemId, {bool rest = false}) {
    state = state.copyWith(
      haveItems: {...state.haveItems, ingredient: itemId},
      addedItems: {...state.addedItems, itemId},
    );
    choose(ingredient, IngredientCheckChoice.have, rest: rest);
  }

  /// Saves the Vorrat items and the ignored ingredients of [check] on the
  /// recipe, so the next check starts from them, and then puts what it
  /// lacks on the shopping list. An ingredient that does not come from the
  /// Vorrat this time gets no Vorrat item on the recipe page. A second try
  /// after a failure is safe: the recipe is saved again and the list skips
  /// what it holds.
  Future<IngredientCheckFinish> finish(IngredientCheckView check) async {
    if (state.isSaving) {
      return IngredientCheckFinish.busy;
    }
    final templates = ref.read(preparedMealTemplateRepositoryProvider);
    final shopping = ref.read(shoppingListNamesServiceProvider);
    final link = ref.keepAlive();
    state = state.copyWith(isSaving: true);
    final draft = check.draft;
    final recipe = check.view.recipe;
    final assignments = {...recipe.recipeIngredientAssignments};
    final ignored = [...recipe.ignoredRecipeIngredients];
    final fromStock = <String>[];
    final notFromStock = <String>[];
    for (final line in [...check.found, ...check.missing]) {
      final ingredient = line.ingredient;
      final added = draft.haveItems[ingredient];
      switch (draft.choiceOf(line)) {
        case IngredientCheckChoice.use:
          assignments[ingredient] = {
            for (final item in line.items) item.id,
            if (draft.restChoiceOf(line) == IngredientCheckChoice.have) ?added,
          }.toList();
          fromStock.add(ingredient);
        case IngredientCheckChoice.have:
          assignments[ingredient] = [?added];
          fromStock.add(ingredient);
        case IngredientCheckChoice.cart:
          notFromStock.add(ingredient);
        case IngredientCheckChoice.ignore:
          ignored.add(ingredient);
      }
    }
    var result = IngredientCheckFinish.recipeFailed;
    try {
      final saved = await templates.save(
        recipe.copyWith(
          recipeIngredientAssignments: assignments,
          ignoredRecipeIngredients: ignored,
          updatedAt: ref.read(clockProvider)(),
        ),
      );
      if (!saved) {
        return result;
      }
      if (ref.mounted) {
        final recipeController = ref.read(
          recipeControllerProvider(recipe.id).notifier,
        )..forgetPicks(fromStock);
        for (final ingredient in notFromStock) {
          recipeController.pick(ingredient, null);
        }
      }
      result = IngredientCheckFinish.listFailed;
      final onList = check.onList;
      if (onList.isNotEmpty) {
        await shopping.addMissing(onList);
      }
      return IngredientCheckFinish.done;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save the ingredient check.',
        name: 'IngredientCheckController',
        error: error,
        stackTrace: stackTrace,
      );
      return result;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false);
      }
      link.close();
    }
  }
}
