import 'dart:developer' show log;

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_cooking_service.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'recipe_controller.g.dart';

/// What the cook changed on the recipe page.
@immutable
class RecipeDraft {
  /// Creates the draft.
  const new({
    this.portions,
    this.picks = const <String, String?>{},
    this.edits = const RecipeEdits(),
    this.withGuide = true,
    this.isCooking = false,
  });

  /// The chosen portions, or `null` for the recipe's own.
  final int? portions;

  /// The Vorrat item picked per line key; `null` means "not from the
  /// Vorrat".
  final Map<String, String?> picks;

  /// What the cook changes in the recipe this time.
  final RecipeEdits edits;

  /// Whether "Kochen" opens the Kochhelfer first, for a recipe with steps.
  final bool withGuide;

  /// Whether "Kochen" is saving the meal.
  final bool isCooking;

  /// Returns a copy with the given values.
  RecipeDraft copyWith({
    int? portions,
    Map<String, String?>? picks,
    RecipeEdits? edits,
    bool? withGuide,
    bool? isCooking,
  }) => RecipeDraft(
    portions: portions ?? this.portions,
    picks: picks ?? this.picks,
    edits: edits ?? this.edits,
    withGuide: withGuide ?? this.withGuide,
    isCooking: isCooking ?? this.isCooking,
  );
}

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

  /// Opens the Kochhelfer before cooking when [withGuide] is set.
  void setWithGuide({required bool withGuide}) {
    state = state.copyWith(withGuide: withGuide);
  }

  /// Cooks the recipe with [edits] this time.
  void setEdits(RecipeEdits edits) {
    state = state.copyWith(edits: edits);
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
