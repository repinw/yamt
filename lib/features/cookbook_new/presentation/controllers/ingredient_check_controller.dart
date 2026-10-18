import 'dart:developer' show log;
import 'dart:math' show max;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_check_save_service.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_state.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_ingredient_texts.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'ingredient_check_controller.g.dart';

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
  IngredientCheckState build(String recipeId) => const IngredientCheckState();

  /// Sets what happens with the ingredient of the line [key], or with its
  /// missing part when [rest] is set.
  void choose(String key, IngredientCheckChoice choice, {bool rest = false}) {
    state = rest
        ? state.copyWith(restChoices: {...state.restChoices, key: choice})
        : state.copyWith(choices: {...state.choices, key: choice});
  }

  /// Takes the ingredient of the line [key] from the Vorrat item [itemId],
  /// or not from the Vorrat when it is `null`. Its choices start over.
  void pick(String key, String? itemId) {
    state = state.copyWith(
      picks: {...state.picks, key: itemId},
      choices: {...state.choices}..remove(key),
      restChoices: {...state.restChoices}..remove(key),
    );
  }

  /// Takes the ingredient of the line [key], or its missing part when
  /// [rest] is set, from the Vorrat item [itemId] that "Hab ich" added.
  void have(String key, String itemId, {bool rest = false}) {
    state = state.copyWith(
      haveItems: {...state.haveItems, key: itemId},
      addedItems: {...state.addedItems, itemId},
    );
    choose(key, IngredientCheckChoice.have, rest: rest);
  }

  /// Cooks [line] of [view] with [amount], for the chosen portions, this
  /// time. The saved amount again undoes the change.
  void setAmount(RecipeView view, RecipeIngredientLine line, int amount) {
    final requirement = line.row.requirement;
    if (requirement == null || amount < 1 || amount == requirement.amount) {
      return;
    }
    final saved = line.isAdded
        ? null
        : ref
              .read(templateIngredientParserProvider)
              .parseRequirement(
                ingredient: line.key,
                selectedPortions: view.portions,
                basePortions: view.basePortions,
              );
    _replace(
      line,
      saved?.amount == amount
          ? line.key
          : recipeIngredientTextFor(
              requirement,
              amount * view.basePortions / view.portions,
            ),
    );
  }

  /// Leaves [line] of [view] out this time, while [RecipeView.canRemove].
  void remove(RecipeView view, RecipeIngredientLine line) {
    if (view.canRemove) {
      _replace(line, null);
    }
  }

  /// Adds [text], written for the chosen portions of [view], this time.
  void add(RecipeView view, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(
      edits: _edits.withAdded(
        recipeAddedText(
          ref.read(templateIngredientParserProvider),
          view,
          trimmed,
        ),
      ),
    );
  }

  /// Drops the changes made in this check; the recipe page's stay.
  void discardEdits() {
    final edits = _recipeEdits;
    // The keys of the dropped ingredients do not come back.
    state = state.copyWith(
      edits: edits.copyWith(nextId: max(edits.nextId, _edits.nextId)),
    );
  }

  /// Saves the changes in the recipe when [save] is set, else for this
  /// cooking only.
  void setSaveEdits({required bool save}) {
    state = state.copyWith(saveEdits: save);
  }

  RecipeEdits get _recipeEdits =>
      ref.read(recipeControllerProvider(recipeId)).edits;

  RecipeEdits get _edits => state.edits ?? _recipeEdits;

  void _replace(RecipeIngredientLine line, String? text) {
    final edits = _edits;
    if (line.isAdded) {
      final added = {...edits.added};
      if (text == null) {
        added.remove(line.key);
      } else {
        added[line.key] = text;
      }
      state = state.copyWith(edits: edits.copyWith(added: added));
      return;
    }
    final changed = {...edits.changed};
    if (text == line.key) {
      changed.remove(line.key);
    } else {
      changed[line.key] = text;
    }
    state = state.copyWith(edits: edits.copyWith(changed: changed));
  }

  /// Saves the Vorrat items and the ignored ingredients of [check] on the
  /// recipe, so the next check starts from them, and then puts what it
  /// lacks on the shopping list. The cook's changes go into the recipe when
  /// [IngredientCheckState.saveEdits] is set, else the recipe page cooks
  /// with them this time and takes the choices for added ingredients as
  /// its picks. An ingredient that does not come from the Vorrat this time
  /// gets no Vorrat item on the recipe page. After
  /// [IngredientCheckFinish.recipeFailed] nothing changed, so a second try
  /// is safe; after [IngredientCheckFinish.listFailed] the recipe holds the
  /// choices, and a new check starts from them.
  Future<IngredientCheckFinish> finish(IngredientCheckView check) async {
    if (state.isSaving) {
      return IngredientCheckFinish.busy;
    }
    final link = ref.keepAlive();
    // Held for both writes, so the workflow and its stores stay alive.
    final workflow = ref.listen(ingredientCheckSaveServiceProvider, (_, _) {});
    final service = workflow.read();
    state = state.copyWith(isSaving: true);
    final draft = check.draft;
    final view = check.view;
    var edits = _edits;
    // Changes for this time only keep the saved recipe as it is; its Vorrat
    // items and ignores go to the saved ingredient.
    final keepEdits = !draft.saveEdits && !edits.isEmpty;
    final recipe = keepEdits ? view.saved : view.recipe;
    final assignments = {...recipe.recipeIngredientAssignments};
    final ignored = [...recipe.ignoredRecipeIngredients];
    final fromStock = <String>[];
    final picks = <String, String?>{};
    for (final line in [...check.found, ...check.missing]) {
      final added = draft.haveItems[line.key];
      final choice = draft.choiceOf(line);
      if (line.isAdded && keepEdits) {
        // An added ingredient is not saved, so the recipe page takes its
        // choice as a pick. ponytail: one pick per line drops a "Hab ich"
        // food for the missing part; a list of picks would keep it.
        switch (choice) {
          case IngredientCheckChoice.use:
            picks[line.key] = line.items.firstOrNull?.id;
          case IngredientCheckChoice.have:
            picks[line.key] = added;
          case IngredientCheckChoice.cart:
            picks[line.key] = null;
          case IngredientCheckChoice.ignore:
            edits = edits.copyWith(added: {...edits.added}..remove(line.key));
        }
        continue;
      }
      // The ingredient as the saved recipe and the recipe page name it
      // after "Fertig".
      final key = keepEdits ? line.key : line.ingredient;
      switch (choice) {
        case IngredientCheckChoice.use:
          assignments[key] = {
            for (final item in line.items) item.id,
            if (draft.restChoiceOf(line) == IngredientCheckChoice.have) ?added,
          }.toList();
          fromStock.add(key);
        case IngredientCheckChoice.have:
          assignments[key] = [?added];
          fromStock.add(key);
        case IngredientCheckChoice.cart:
          picks[key] = null;
        case IngredientCheckChoice.ignore:
          if (!ignored.contains(key)) {
            ignored.add(key);
          }
      }
    }
    try {
      await service.save(
        recipe: recipe,
        assignments: assignments,
        ignored: ignored,
        onList: check.onList,
        onRecipeSaved: () {
          if (!ref.mounted) {
            return;
          }
          // The saved recipe holds the changes now. Keys of added
          // ingredients do not come back, so no pick finds another one.
          final rest = keepEdits ? edits : RecipeEdits(nextId: edits.nextId);
          state = state.copyWith(edits: rest);
          final recipeController =
              ref.read(recipeControllerProvider(recipe.id).notifier)
                ..setEdits(rest)
                ..forgetPicks(fromStock);
          for (final MapEntry(:key, :value) in picks.entries) {
            recipeController.pick(key, value);
          }
        },
      );
      return IngredientCheckFinish.done;
    } on IngredientCheckSaveFailure catch (failure, stackTrace) {
      log(
        'Failed to save the ingredient check.',
        name: 'IngredientCheckController',
        error: failure,
        stackTrace: stackTrace,
      );
      return failure.recipeSaved
          ? IngredientCheckFinish.listFailed
          : IngredientCheckFinish.recipeFailed;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false);
      }
      workflow.close();
      link.close();
    }
  }
}
