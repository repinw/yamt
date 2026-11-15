import 'dart:convert';

import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

/// Reads the answer of the recipe idea template, which the template's JSON
/// mode returns as plain JSON.
class AiChefRecipeResponseParser {
  /// Creates the parser.
  const new();

  /// The recipe idea in [text], made at [now]: an unsaved recipe with the
  /// nutrition of the whole dish, the estimate of one portion with the
  /// nutrition of each ingredient line, the weight of each line, and the
  /// prompt for its picture. Throws a [FormatException] when a field is
  /// missing, has another type, or a number is negative.
  ///
  /// The ingredient lines are the one source of the nutrition: the dish is
  /// the sum of its lines, a portion that sum divided by the portions. The
  /// answer's own totals of a portion are not read.
  ({PreparedMeal recipe, String imagePrompt}) parse(
    String text, {
    required DateTime now,
  }) {
    final json = _map(jsonDecode(text), 'answer');
    final portions = switch (json['portions']) {
      final int value when value > 0 => value,
      final other => throw FormatException('Bad portions: $other'),
    };
    final lines = [
      for (final line in _list(json, 'ingredients')) _line(_map(line, 'line')),
    ];
    if (lines.isEmpty) {
      throw const FormatException('A recipe idea without ingredients');
    }
    final texts = [for (final line in lines) line.text];
    final dish = lines
        .map((line) => line.nutrition)
        .reduce(
          (sum, line) => RecipeLineNutrition(
            kcal: sum.kcal + line.kcal,
            protein: sum.protein + line.protein,
            carbs: sum.carbs + line.carbs,
            fat: sum.fat + line.fat,
          ),
        );
    final portion = dish.scaled(1 / portions);
    // A text that occurs twice cannot say which weight is meant: the cook
    // gives the amount in the cook flow.
    final repeated = {
      for (final line in texts)
        if (texts.indexOf(line) != texts.lastIndexOf(line)) line,
    };

    return (
      recipe: PreparedMeal(
        id: '',
        name: _text(json, 'name'),
        totalPortions: portions,
        remainingPortions: portions,
        totalKcal: dish.kcal,
        totalProtein: dish.protein,
        totalCarbs: dish.carbs,
        totalFat: dish.fat,
        createdAt: now,
        updatedAt: now,
        components: const [],
        recipeIngredients: texts,
        recipeInstructions: [
          for (final step in _list(json, 'instructions'))
            switch (step) {
              final String value when value.trim().isNotEmpty => value.trim(),
              final other => throw FormatException('Bad step: $other'),
            },
        ],
        recipeEstimate: RecipeEstimate(
          kcal: portion.kcal,
          protein: portion.protein,
          carbs: portion.carbs,
          fat: portion.fat,
          portions: portions,
          linesKey: recipeLinesKey(texts),
          createdAt: now,
          lines: [for (final line in lines) line.nutrition],
        ),
        recipeLineWeights: {
          for (final line in lines)
            if (!repeated.contains(line.text)) line.text: ?line.weight,
        },
      ),
      imagePrompt: _text(json, 'image_prompt'),
    );
  }

  // One ingredient line: its text, the weight of the whole line (none for 0,
  // such as "Salz nach Geschmack", whose unit is not read), and its
  // nutrition.
  static ({
    String text,
    RecipeLineWeight? weight,
    RecipeLineNutrition nutrition,
  })
  _line(Map<String, dynamic> json) {
    final amount = switch (json['amount']) {
      final int value when value >= 0 => value,
      final other => throw FormatException('Bad line amount: $other'),
    };
    return (
      text: _text(json, 'text'),
      weight: amount == 0
          ? null
          : RecipeLineWeight(
              amount: amount,
              unit: switch (json['unit']) {
                'g' => RecipeLineWeightUnit.gram,
                'ml' => RecipeLineWeightUnit.milliliter,
                final other => throw FormatException(
                  'Unknown line unit: $other',
                ),
              },
              source: RecipeLineWeightSource.ai,
            ),
      nutrition: RecipeLineNutrition(
        kcal: _number(json, 'kcal'),
        protein: _number(json, 'protein'),
        carbs: _number(json, 'carbs'),
        fat: _number(json, 'fat'),
      ),
    );
  }

  static Map<String, dynamic> _map(Object? value, String what) =>
      switch (value) {
        final Map<String, dynamic> map => map,
        final other => throw FormatException('Bad $what: $other'),
      };

  static List<dynamic> _list(Map<String, dynamic> json, String key) =>
      switch (json[key]) {
        final List<dynamic> list => list,
        final other => throw FormatException('Bad $key: $other'),
      };

  static String _text(Map<String, dynamic> json, String key) =>
      switch (json[key]) {
        final String value when value.trim().isNotEmpty => value.trim(),
        final other => throw FormatException('Bad $key: $other'),
      };

  static double _number(Map<String, dynamic> json, String key) =>
      switch (json[key]) {
        final num value when value >= 0 => value.toDouble(),
        final other => throw FormatException('Bad $key: $other'),
      };
}
