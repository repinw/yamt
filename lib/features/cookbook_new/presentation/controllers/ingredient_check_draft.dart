import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';

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
    this.edits,
    this.saveEdits = false,
    this.isSaving = false,
  });

  /// The choice per line key that the cook changed.
  final Map<String, IngredientCheckChoice> choices;

  /// The choice for the missing part of a partly stocked ingredient.
  final Map<String, IngredientCheckChoice> restChoices;

  /// The Vorrat item that "Hab ich" added per line key.
  final Map<String, String> haveItems;

  /// Every Vorrat item that "Hab ich" added in this check, also the ones a
  /// later "Hab ich" replaced.
  final Set<String> addedItems;

  /// The Vorrat item picked in the check per line key; `null` means "not
  /// from the Vorrat".
  final Map<String, String?> picks;

  /// What the cook changes in the recipe, or `null` while the check keeps
  /// the recipe page's changes.
  final RecipeEdits? edits;

  /// Whether "Fertig" saves [edits] in the recipe instead of this time only.
  final bool saveEdits;

  /// Whether "Fertig" is saving the choices.
  final bool isSaving;

  /// The choice for [line]: a stocked ingredient starts from the Vorrat, a
  /// missing one on the shopping list.
  IngredientCheckChoice choiceOf(RecipeIngredientLine line) =>
      choices[line.key] ??
      (line.items.isEmpty
          ? IngredientCheckChoice.cart
          : IngredientCheckChoice.use);

  /// The choice for the missing part of [line]; it starts on the list.
  IngredientCheckChoice restChoiceOf(RecipeIngredientLine line) =>
      restChoices[line.key] ?? IngredientCheckChoice.cart;

  /// Returns a copy with the given values.
  IngredientCheckDraft copyWith({
    Map<String, IngredientCheckChoice>? choices,
    Map<String, IngredientCheckChoice>? restChoices,
    Map<String, String>? haveItems,
    Set<String>? addedItems,
    Map<String, String?>? picks,
    RecipeEdits? edits,
    bool? saveEdits,
    bool? isSaving,
  }) => IngredientCheckDraft(
    choices: choices ?? this.choices,
    restChoices: restChoices ?? this.restChoices,
    haveItems: haveItems ?? this.haveItems,
    addedItems: addedItems ?? this.addedItems,
    picks: picks ?? this.picks,
    edits: edits ?? this.edits,
    saveEdits: saveEdits ?? this.saveEdits,
    isSaving: isSaving ?? this.isSaving,
  );
}
