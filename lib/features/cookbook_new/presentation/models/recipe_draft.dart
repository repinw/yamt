import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// What the cook changed on the recipe page.
@immutable
class RecipeDraft {
  /// Creates the draft.
  const new({
    this.portions,
    this.isCooking = false,
    this.failedEstimates = const <String>{},
  });

  /// The chosen portions, or `null` for the recipe's own.
  final int? portions;

  /// Whether a Vorlage's "Kochen" is saving the meal.
  final bool isCooking;

  /// The [RecipeIngredientLines.recipeEstimateKey]s whose estimate ended
  /// without one while the page was open: it failed, the AI's answer could
  /// not be used, or the lines changed meanwhile.
  final Set<String> failedEstimates;

  /// Whether the page waits for the estimate of the saved [recipe]: it has
  /// lines without a fitting estimate, and their estimate has not ended
  /// without one. The page estimates every such recipe it shows.
  bool waitsForEstimate(PreparedMeal recipe) =>
      recipe.needsRecipeEstimate &&
      !failedEstimates.contains(recipe.recipeEstimateKey);

  /// Returns a copy with the given values.
  RecipeDraft copyWith({
    int? portions,
    bool? isCooking,
    Set<String>? failedEstimates,
  }) => RecipeDraft(
    portions: portions ?? this.portions,
    isCooking: isCooking ?? this.isCooking,
    failedEstimates: failedEstimates ?? this.failedEstimates,
  );
}
