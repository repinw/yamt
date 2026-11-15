import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

final _day = DateTime.utc(2026, 11, 7);

RecipeLineWeight _ai(int grams, {bool ml = false}) => RecipeLineWeight(
  amount: grams,
  unit: ml ? RecipeLineWeightUnit.milliliter : RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.ai,
);

RecipeLineWeight _typed(int grams) => RecipeLineWeight(
  amount: grams,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.user,
);

RecipeEstimate _estimate(
  List<String> lines, {
  int portions = 2,
  double kcal = 400,
}) => RecipeEstimate(
  kcal: kcal,
  protein: 10,
  carbs: 50,
  fat: 5,
  portions: portions,
  linesKey: recipeLinesKey(lines),
  createdAt: _day,
);

PreparedMeal _recipe({
  List<String> ingredients = const ['1 Zwiebel', '200 g Mehl', 'Salz'],
  int totalPortions = 2,
  RecipeEstimate? estimate,
  Map<String, RecipeLineWeight> weights = const {},
}) => PreparedMeal(
  id: 'recipe-1',
  name: 'Brot',
  totalPortions: totalPortions,
  remainingPortions: totalPortions,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _day,
  updatedAt: _day,
  components: const [],
  recipeIngredients: ingredients,
  recipeEstimate: estimate,
  recipeLineWeights: weights,
);

void main() {
  group('RecipeEstimate', () {
    test('recipeLinesKey is the lines in their order', () {
      expect(recipeLinesKey(['a', 'b']), 'a\nb');
      expect(recipeLinesKey(['b', 'a']), isNot(recipeLinesKey(['a', 'b'])));
      expect(recipeLinesKey(const []), '');
    });

    test('isFor needs the same lines in the same order and the same '
        'portions', () {
      final estimate = _estimate(['1 Zwiebel', 'Salz']);

      expect(estimate.isFor(['1 Zwiebel', 'Salz'], 2), isTrue);
      expect(estimate.isFor(['1 Zwiebel', 'Salz'], 3), isFalse);
      expect(estimate.isFor(['Salz', '1 Zwiebel'], 2), isFalse);
      expect(estimate.isFor(['1 Zwiebel'], 2), isFalse);
      expect(estimate.isFor(['1 Zwiebel', 'Salz', 'Pfeffer'], 2), isFalse);
    });

    test('keeps every value through json', () {
      final estimate = _estimate(['1 Zwiebel'], kcal: 412.5);

      final read = RecipeEstimate.fromJson(estimate.toJson());

      expect(read, estimate);
      expect(read.hashCode, estimate.hashCode);
      expect(estimate.toJson()['lines_key'], '1 Zwiebel');
    });

    test('RecipeLineWeight reads its json and knows who set it', () {
      final json = _ai(150, ml: true).toJson();

      expect(json['unit'], 'ml');
      expect(json['source'], 'ai');
      expect(RecipeLineWeight.fromJson(json), _ai(150, ml: true));
      expect(_ai(1).isFromUser, isFalse);
      expect(_typed(1).isFromUser, isTrue);
    });
  });

  group('RecipeEditorLine', () {
    test('keptWeight keeps a weight only while the text is the saved one', () {
      expect(
        RecipeEditorLine(text: 'a', saved: 'a', weight: _ai(10)).keptWeight,
        _ai(10),
      );
      expect(
        RecipeEditorLine(text: 'a', saved: 'a', weight: _typed(10)).keptWeight,
        _typed(10),
      );
      // Rewritten: the weight was meant for the old text, whoever gave it.
      expect(
        RecipeEditorLine(text: 'b', saved: 'a', weight: _ai(10)).keptWeight,
        isNull,
      );
      expect(
        RecipeEditorLine(text: 'b', saved: 'a', weight: _typed(10)).keptWeight,
        isNull,
      );
      expect(
        RecipeEditorLine(text: 'b', weight: _typed(10)).keptWeight,
        isNull,
      );
      expect(const RecipeEditorLine(text: 'b').keptWeight, isNull);
    });

    test('withText and withWeight change one thing', () {
      final line = RecipeEditorLine(text: 'a', saved: 'a', weight: _ai(10));

      expect(line.withText('b').text, 'b');
      expect(line.withText('b').saved, 'a');
      expect(line.withText('b').weight, _ai(10));
      expect(line.withWeight(null).weight, isNull);
      expect(line.withWeight(_typed(5)).text, 'a');
    });

    test('recipeLineWeightsOf maps the kept weights by text', () {
      final weights = recipeLineWeightsOf([
        RecipeEditorLine(text: 'a', saved: 'a', weight: _ai(10)),
        RecipeEditorLine(text: 'c', saved: 'b', weight: _ai(20)),
        RecipeEditorLine(text: 'd', saved: 'd', weight: _typed(30)),
        RecipeEditorLine(text: 'f', weight: _typed(40)),
        const RecipeEditorLine(text: 'e'),
      ]);

      expect(weights, {'a': _ai(10), 'd': _typed(30)});
    });

    test('lines with the same text share one weight, a typed one first', () {
      const saved = '1 EL Butter';
      final onFirst = recipeLineWeightsOf([
        RecipeEditorLine(text: saved, saved: saved, weight: _typed(99)),
        RecipeEditorLine(text: saved, saved: saved, weight: _ai(30)),
      ]);
      final onLast = recipeLineWeightsOf([
        RecipeEditorLine(text: saved, saved: saved, weight: _ai(30)),
        RecipeEditorLine(text: saved, saved: saved, weight: _typed(99)),
      ]);
      final bothAi = recipeLineWeightsOf([
        RecipeEditorLine(text: saved, saved: saved, weight: _ai(15)),
        RecipeEditorLine(text: saved, saved: saved, weight: _ai(30)),
      ]);

      expect(onFirst, {saved: _typed(99)});
      expect(onLast, {saved: _typed(99)});
      expect(bothAi, {saved: _ai(30)});
    });
  });

  group('withIngredientLines', () {
    test('moves what the recipe keeps per line to the renamed line', () {
      final recipe = _recipe().copyWith(
        recipeIngredientAssignments: {
          '1 Zwiebel': ['onion'],
          '200 g Mehl': ['flour'],
        },
        recipeIngredientAmountConversions: {
          '1 Zwiebel': const RecipeIngredientAmountConversion(
            amountPerPiece: 150,
            unit: InventoryAmountUnit.gram,
          ),
        },
        ignoredRecipeIngredients: ['Salz'],
        pendingRecipeIngredients: ['1 Zwiebel'],
        ignoredPendingRecipeIngredients: ['Salz'],
      );

      final edited = recipe.withIngredientLines([
        const RecipeEditorLine(text: '2 Zwiebeln', saved: '1 Zwiebel'),
        const RecipeEditorLine(text: '200 g Mehl', saved: '200 g Mehl'),
        const RecipeEditorLine(text: 'Meersalz', saved: 'Salz'),
      ]);

      expect(edited.recipeIngredients, [
        '2 Zwiebeln',
        '200 g Mehl',
        'Meersalz',
      ]);
      expect(edited.recipeIngredientAssignments, {
        '2 Zwiebeln': ['onion'],
        '200 g Mehl': ['flour'],
      });
      expect(edited.recipeIngredientAmountConversions.keys, ['2 Zwiebeln']);
      expect(edited.ignoredRecipeIngredients, ['Meersalz']);
      expect(edited.pendingRecipeIngredients, ['2 Zwiebeln']);
      expect(edited.ignoredPendingRecipeIngredients, ['Meersalz']);
    });

    group('two lines with the same text', () {
      const butter = '1 EL Butter';
      final recipe = _recipe(ingredients: const [butter, 'Salz', butter])
          .copyWith(
            recipeIngredientAssignments: {
              butter: ['butter'],
            },
            ignoredRecipeIngredients: [butter],
          );

      test('renaming the last one leaves everything on the other', () {
        final edited = recipe.withIngredientLines([
          const RecipeEditorLine(text: butter, saved: butter),
          const RecipeEditorLine(text: 'Salz', saved: 'Salz'),
          const RecipeEditorLine(text: '2 EL Butter', saved: butter),
        ]);

        expect(edited.recipeIngredients, [butter, 'Salz', '2 EL Butter']);
        expect(edited.recipeIngredientAssignments, {
          butter: ['butter'],
        });
        expect(edited.ignoredRecipeIngredients, [butter]);
      });

      test('renaming the first one leaves everything on the other', () {
        final edited = recipe.withIngredientLines([
          const RecipeEditorLine(text: '2 EL Butter', saved: butter),
          const RecipeEditorLine(text: 'Salz', saved: 'Salz'),
          const RecipeEditorLine(text: butter, saved: butter),
        ]);

        expect(edited.recipeIngredientAssignments, {
          butter: ['butter'],
        });
        expect(edited.ignoredRecipeIngredients, [butter]);
      });

      test('renaming both moves everything to the last new text', () {
        final edited = recipe.withIngredientLines([
          const RecipeEditorLine(text: '2 EL Butter', saved: butter),
          const RecipeEditorLine(text: 'Salz', saved: 'Salz'),
          const RecipeEditorLine(text: '3 EL Butter', saved: butter),
        ]);

        expect(edited.recipeIngredientAssignments, {
          '3 EL Butter': ['butter'],
        });
        expect(edited.ignoredRecipeIngredients, ['3 EL Butter']);
      });
    });

    test('a removed line takes its keys along, a new line has none', () {
      final recipe = _recipe().copyWith(
        recipeIngredientAssignments: {
          '1 Zwiebel': ['onion'],
          '200 g Mehl': ['flour'],
        },
        ignoredRecipeIngredients: ['Salz'],
        pendingRecipeIngredients: ['1 Zwiebel'],
      );

      final edited = recipe.withIngredientLines([
        const RecipeEditorLine(text: '200 g Mehl', saved: '200 g Mehl'),
        const RecipeEditorLine(text: 'Pfeffer'),
      ]);

      expect(edited.recipeIngredients, ['200 g Mehl', 'Pfeffer']);
      expect(edited.recipeIngredientAssignments, {
        '200 g Mehl': ['flour'],
      });
      expect(edited.ignoredRecipeIngredients, isEmpty);
      expect(edited.pendingRecipeIngredients, isEmpty);
    });

    test('keys that name no saved line stay', () {
      final recipe = _recipe().copyWith(
        recipeIngredientAssignments: {
          '+0': ['feta'],
          '1 Zwiebel': ['onion'],
        },
      );

      final edited = recipe.withIngredientLines([
        const RecipeEditorLine(text: '1 Zwiebel', saved: '1 Zwiebel'),
      ]);

      expect(edited.recipeIngredientAssignments, {
        '+0': ['feta'],
        '1 Zwiebel': ['onion'],
      });
    });

    test('a key with spaces around the line moves with the trimmed line', () {
      final recipe = _recipe(ingredients: [' 1 Zwiebel ']).copyWith(
        recipeIngredientAssignments: {
          '1 Zwiebel': ['onion'],
        },
      );

      final edited = recipe.withIngredientLines([
        const RecipeEditorLine(text: '2 Zwiebeln', saved: ' 1 Zwiebel '),
      ]);

      expect(edited.recipeIngredientAssignments, {
        '2 Zwiebeln': ['onion'],
      });
    });

    test('the weights are the ones the lines keep, by their new text', () {
      final recipe = _recipe(
        weights: {
          '1 Zwiebel': _ai(150),
          '200 g Mehl': _ai(200),
          'Salz': _typed(5),
        },
      );

      final edited = recipe.withIngredientLines([
        RecipeEditorLine(
          text: '1 Zwiebel',
          saved: '1 Zwiebel',
          weight: _ai(150),
        ),
        // The weight was for the old text.
        RecipeEditorLine(
          text: '300 g Mehl',
          saved: '200 g Mehl',
          weight: _ai(200),
        ),
        RecipeEditorLine(text: 'Salz', saved: 'Salz', weight: _typed(5)),
      ]);

      expect(edited.recipeLineWeights, {
        '1 Zwiebel': _ai(150),
        'Salz': _typed(5),
      });
    });
  });

  group('withRecipeEstimate', () {
    test('sets the estimate and one weight per line in order', () {
      final recipe = _recipe();
      final estimate = _estimate(recipe.recipeIngredients);

      final estimated = recipe.withRecipeEstimate(estimate, [
        _ai(150),
        _ai(200),
        null,
      ]);

      expect(estimated.recipeEstimate, estimate);
      expect(estimated.recipeLineWeights, {
        '1 Zwiebel': _ai(150),
        '200 g Mehl': _ai(200),
      });
    });

    test('a weight the cook typed stays, every other takes the AI weight', () {
      final recipe = _recipe(
        weights: {'1 Zwiebel': _typed(90), '200 g Mehl': _ai(10)},
      );

      final estimated = recipe.withRecipeEstimate(
        _estimate(recipe.recipeIngredients),
        [_ai(150), _ai(200), _ai(3)],
      );

      expect(estimated.recipeLineWeights, {
        '1 Zwiebel': _typed(90),
        '200 g Mehl': _ai(200),
        'Salz': _ai(3),
      });
    });

    test('a missing answer for a line takes an AI weight away', () {
      final recipe = _recipe(weights: {'200 g Mehl': _ai(10)});

      final estimated = recipe.withRecipeEstimate(
        _estimate(recipe.recipeIngredients),
        [_ai(150)],
      );

      expect(estimated.recipeLineWeights, {'1 Zwiebel': _ai(150)});
    });

    test('lines with the same text share the last answer', () {
      const butter = '1 EL Butter';
      final recipe = _recipe(ingredients: const [butter, butter]);

      final estimated = recipe.withRecipeEstimate(
        _estimate(recipe.recipeIngredients),
        [_ai(15), _ai(30)],
      );

      expect(estimated.recipeLineWeights, {butter: _ai(30)});
    });
  });

  group('needsRecipeEstimate', () {
    test('a recipe without lines needs none', () {
      expect(_recipe(ingredients: const []).needsRecipeEstimate, isFalse);
    });

    test('a recipe with lines and no estimate needs one', () {
      expect(_recipe().needsRecipeEstimate, isTrue);
    });

    test('a fitting estimate needs no new one', () {
      final recipe = _recipe();

      expect(
        _recipe(estimate: _estimate(recipe.recipeIngredients))
            .needsRecipeEstimate,
        isFalse,
      );
    });

    test('changed lines or portions need a new estimate', () {
      final lines = _recipe().recipeIngredients;
      final estimate = _estimate(lines);

      expect(
        _recipe(
          ingredients: [...lines, 'Pfeffer'],
          estimate: estimate,
        ).needsRecipeEstimate,
        isTrue,
      );
      expect(
        _recipe(totalPortions: 4, estimate: estimate).needsRecipeEstimate,
        isTrue,
      );
    });
  });

  group('fittingRecipeEstimate', () {
    test('is the estimate while it fits the lines and portions', () {
      final lines = _recipe().recipeIngredients;
      final estimate = _estimate(lines);

      expect(_recipe(estimate: estimate).fittingRecipeEstimate, estimate);
    });

    test('is null without an estimate', () {
      expect(_recipe().fittingRecipeEstimate, isNull);
    });

    test('is null after the lines or the portions changed', () {
      final lines = _recipe().recipeIngredients;
      final estimate = _estimate(lines);

      expect(
        _recipe(
          ingredients: [...lines, 'Pfeffer'],
          estimate: estimate,
        ).fittingRecipeEstimate,
        isNull,
      );
      expect(
        _recipe(totalPortions: 4, estimate: estimate).fittingRecipeEstimate,
        isNull,
      );
    });
  });
}
