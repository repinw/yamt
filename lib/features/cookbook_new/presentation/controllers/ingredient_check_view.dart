import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'ingredient_check_view.g.dart';

/// A recipe as the ingredient check shows it. [view] leaves out the foods
/// that "Hab ich" added, so an ingredient stays in the step it started in.
@immutable
class IngredientCheckView {
  /// Sorts the ingredients of [view] by [draft].
  new({required this.view, required this.draft})
    : found = [
        for (final line in view.activeLines)
          if (line.items.isNotEmpty) line,
      ],
      missing = [
        for (final line in view.activeLines)
          if (line.items.isEmpty) line,
      ];

  /// The recipe for this cooking.
  final RecipeView view;

  /// The cook's choices.
  final IngredientCheckDraft draft;

  /// The ingredients the Vorrat holds.
  final List<RecipeIngredientLine> found;

  /// The ingredients the Vorrat lacks.
  final List<RecipeIngredientLine> missing;

  /// The found ingredients taken from the Vorrat that it holds only part of.
  List<RecipeIngredientLine> get rests => [
    for (final line in found)
      if (line.isPartial && draft.choiceOf(line) == IngredientCheckChoice.use)
        line,
  ];

  /// How many rows the "Fehlt" step has.
  int get missingCount => missing.length + rests.length;

  /// What comes from the Vorrat, as an open row of a meal names it.
  List<String> get fromStock => [
    for (final line in found)
      if (draft.choiceOf(line) == IngredientCheckChoice.use)
        if (draft.restChoiceOf(line) == IngredientCheckChoice.have)
          line.label
        else
          line.stockedLabel ?? line.label,
    for (final line in missing)
      if (draft.choiceOf(line) == IngredientCheckChoice.have) line.label,
  ];

  /// What "Fertig" puts on the shopping list.
  List<String> get onList => [
    for (final line in [...found, ...missing])
      if (draft.choiceOf(line) == IngredientCheckChoice.cart) line.label,
    for (final line in rests)
      if (draft.restChoiceOf(line) == IngredientCheckChoice.cart)
        line.shoppingLabel,
  ];

  /// What is left out this time.
  List<String> get ignored => [
    for (final line in [...found, ...missing])
      if (draft.choiceOf(line) == IngredientCheckChoice.ignore) line.label,
    for (final line in rests)
      if (draft.restChoiceOf(line) == IngredientCheckChoice.ignore)
        line.shoppingLabel,
  ];
}

/// The recipe [recipeId] as the ingredient check shows it, or `null` when
/// the recipe is gone. It starts from the recipe page's portions and picks;
/// the check's own picks win, and the foods that "Hab ich" added are left
/// out.
@riverpod
AsyncValue<IngredientCheckView?> ingredientCheckView(
  Ref ref,
  String recipeId,
  String localeCode,
) {
  final draft = ref.watch(ingredientCheckControllerProvider(recipeId));
  final recipeDraft = ref.watch(recipeControllerProvider(recipeId));
  return buildRecipeView(
    recipeId: recipeId,
    templates: ref.watch(cookbookTemplatesProvider),
    items: ref.watch(inventoryQuickEatItemsProvider),
    parser: ref.watch(templateIngredientParserProvider),
    localeCode: localeCode,
    portions: recipeDraft.portions,
    picks: {...recipeDraft.picks, ...draft.picks},
    hiddenItemIds: draft.addedItems,
  ).whenData(
    (view) =>
        view == null ? null : IngredientCheckView(view: view, draft: draft),
  );
}
