import 'package:meta/meta.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What the cook changes in a recipe for one cooking. Texts are written for
/// the recipe's own portions, like the saved ingredients.
@immutable
class RecipeEdits {
  /// Creates the edits.
  const new({
    this.changed = const <String, String?>{},
    this.added = const <String, String>{},
    this.nextId = 0,
  });

  /// The new text per saved ingredient; `null` leaves it out.
  final Map<String, String?> changed;

  /// Ingredients the recipe does not have, by their line key.
  final Map<String, String> added;

  /// The number for the line key of the next added ingredient. It only
  /// grows, so a key never comes back for another ingredient.
  final int nextId;

  /// Whether nothing changes.
  bool get isEmpty => changed.isEmpty && added.isEmpty;

  /// The line key that [withAdded] gives the next ingredient.
  String get nextKey => '+$nextId';

  /// Returns a copy with [text] added under [nextKey].
  RecipeEdits withAdded(String text) => RecipeEdits(
    changed: changed,
    added: {...added, nextKey: text},
    nextId: nextId + 1,
  );

  /// Returns a copy with the given values.
  RecipeEdits copyWith({
    Map<String, String?>? changed,
    Map<String, String>? added,
    int? nextId,
  }) => RecipeEdits(
    changed: changed ?? this.changed,
    added: added ?? this.added,
    nextId: nextId ?? this.nextId,
  );
}

/// One change for the summary: the old and the new amount for the chosen
/// portions (`null` without one), whether the ingredient is new, and
/// whether it is left out.
typedef RecipeChange = ({
  String food,
  TemplateIngredientRequirement? from,
  TemplateIngredientRequirement? to,
  bool added,
  bool removed,
});
