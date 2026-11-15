import 'package:meta/meta.dart';

/// What the editor of a new recipe does first.
enum RecipeEditorStart {
  /// Nothing: the cook types.
  blank,

  /// Scans pages of a recipe.
  scan,

  /// Adds the lines on the clipboard.
  paste,
}

/// The route arguments of the editor of a new recipe.
@immutable
class RecipeEditorRouteArgs {
  /// Creates the arguments.
  const new({
    this.start = RecipeEditorStart.blank,
    this.recipeUrl,
    this.name = '',
    this.portions,
    this.sharedText,
  });

  /// What the editor does first.
  final RecipeEditorStart start;

  /// The link of a recipe page that could not be read; the new recipe keeps
  /// it as its source.
  final String? recipeUrl;

  /// The name the cook typed before that page could not be read; empty when
  /// there is none.
  final String name;

  /// The portion count the cook typed before that page could not be read;
  /// `null` when there is none.
  final int? portions;

  /// Text another app shared, which the editor pastes at once.
  final String? sharedText;
}
