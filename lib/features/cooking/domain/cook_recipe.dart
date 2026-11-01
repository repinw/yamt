import 'package:meta/meta.dart';

/// One ingredient line of a recipe. Its `id` stays the same however its
/// text or amount changes, so choices never hang on the text.
typedef RecipeLine = ({String id, String text});

/// A recipe to cook: its lines for [portions] portions.
@immutable
class CookRecipe {
  /// Creates a recipe.
  const new({
    required this.id,
    required this.name,
    required this.portions,
    required this.lines,
    this.imageAssetId,
    this.imageUrl,
  });

  /// The id of the recipe.
  final String id;

  /// The name, which the cooked meal takes unless the cook renames it.
  final String name;

  /// The portions the lines are written for, at least one.
  final int portions;

  /// The ingredient lines in recipe order.
  final List<RecipeLine> lines;

  /// The stored photo of the recipe, if any.
  final String? imageAssetId;

  /// The web photo of the recipe, if any.
  final String? imageUrl;
}
