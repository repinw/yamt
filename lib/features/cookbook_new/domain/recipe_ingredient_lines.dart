import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

/// One line of a recipe in the editor: its text now, the text it has on
/// the saved recipe, if it came from there, and the rough weight of an
/// ingredient line.
@immutable
class RecipeEditorLine {
  /// Creates a line with [text], from the saved line [saved] if any.
  const new({required this.text, this.saved, this.weight});

  /// The line as it reads now.
  final String text;

  /// The line's text on the saved recipe; `null` for a new line.
  final String? saved;

  /// The rough weight of the whole ingredient line; `null` without one.
  final RecipeLineWeight? weight;

  /// The line with the text [text], from the same saved line.
  RecipeEditorLine withText(String text) =>
      RecipeEditorLine(text: text, saved: saved, weight: weight);

  /// The line with the [weight], or without one when it is `null`.
  RecipeEditorLine withWeight(RecipeLineWeight? weight) =>
      RecipeEditorLine(text: text, saved: saved, weight: weight);

  /// The weight the recipe keeps for the line: none once the text changed,
  /// since the weight was meant for the old text ("250 g Mehl" turned
  /// "500 g Mehl"); the next estimate fills it.
  RecipeLineWeight? get keptWeight => text == saved ? weight : null;
}

/// Edits of the ingredient lines of a saved recipe.
extension RecipeIngredientLines on PreparedMeal {
  /// The recipe with [lines] as its ingredients. What the recipe keeps per
  /// line text (Vorrat items, amount conversions, ignored and open lines)
  /// moves to the new text of its line and goes with a removed line. Keys
  /// that name no saved line stay as they are. The line weights are the
  /// ones [lines] keep ([RecipeEditorLine.keptWeight]).
  PreparedMeal withIngredientLines(List<RecipeEditorLine> lines) {
    final renamed = <String, String>{
      for (final line in lines)
        if (line.saved case final saved?) ...{
          saved: line.text,
          saved.trim(): line.text.trim(),
        },
      // A line that kept its text keeps what that text holds, also when a
      // second line with the same text got a new one.
      for (final line in lines)
        if (line.saved == line.text) ...{
          line.text: line.text,
          line.text.trim(): line.text.trim(),
        },
    };
    final removed = {
      for (final ingredient in recipeIngredients) ...{
        ingredient,
        ingredient.trim(),
      },
    }.difference(renamed.keys.toSet());

    String? moved(String key) =>
        renamed[key] ?? (removed.contains(key) ? null : key);
    List<String> movedList(List<String> keys) => [
      for (final key in keys) ?moved(key),
    ];

    return copyWith(
      recipeIngredients: [for (final line in lines) line.text],
      recipeIngredientAssignments: {
        for (final MapEntry(:key, :value)
            in recipeIngredientAssignments.entries)
          ?moved(key): value,
      },
      recipeIngredientAmountConversions: {
        for (final MapEntry(:key, :value)
            in recipeIngredientAmountConversions.entries)
          ?moved(key): value,
      },
      ignoredRecipeIngredients: movedList(ignoredRecipeIngredients),
      pendingRecipeIngredients: movedList(pendingRecipeIngredients),
      ignoredPendingRecipeIngredients: movedList(
        ignoredPendingRecipeIngredients,
      ),
      recipeLineWeights: recipeLineWeightsOf(lines),
    );
  }

  /// The recipe with the AI's [estimate] and its [weights], one per
  /// ingredient line in order (`null` for a line it gave none). A weight the
  /// cook typed stays; every other line takes the AI's weight. Lines with the
  /// same text share one weight, since the recipe keeps them by text: the
  /// last answer for that text.
  PreparedMeal withRecipeEstimate(
    RecipeEstimate estimate,
    List<RecipeLineWeight?> weights,
  ) => copyWith(
    recipeEstimate: estimate,
    recipeLineWeights: {
      for (final (index, line) in recipeIngredients.indexed)
        line: ?switch (recipeLineWeights[line]) {
          final typed? when typed.isFromUser => typed,
          _ => weights.elementAtOrNull(index),
        },
    },
  );

  /// Whether the recipe has ingredient lines without an [recipeEstimate]
  /// made from them for its portions.
  bool get needsRecipeEstimate =>
      recipeIngredients.isNotEmpty && fittingRecipeEstimate == null;

  /// What an estimate of the recipe is made for: its id, portions, and
  /// ingredient lines. A changed line or portion count is a new key.
  String get recipeEstimateKey =>
      '$id|$totalPortions|${recipeLinesKey(recipeIngredients)}';

  /// The [recipeEstimate] while it fits the ingredient lines and portions;
  /// `null` before it comes and after they change.
  RecipeEstimate? get fittingRecipeEstimate => switch (recipeEstimate) {
    final estimate? when estimate.isFor(recipeIngredients, totalPortions) =>
      estimate,
    _ => null,
  };
}

/// The weights the recipe keeps for [lines], by line text. Lines with the
/// same text share one weight: the cook's over the AI's, else the last one.
Map<String, RecipeLineWeight> recipeLineWeightsOf(
  List<RecipeEditorLine> lines,
) {
  final weights = <String, RecipeLineWeight>{};
  for (final line in lines) {
    final kept = line.keptWeight;
    if (kept != null &&
        (kept.isFromUser || !(weights[line.text]?.isFromUser ?? false))) {
      weights[line.text] = kept;
    }
  }
  return weights;
}
