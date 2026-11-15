import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_recipe_response_parser.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

final _now = DateTime.utc(2026, 11, 13, 10);

Map<String, Object?> _answer() => {
  'name': ' Tomato Pasta ',
  'portions': 2,
  'ingredients': [
    {
      'text': '200 g pasta',
      'amount': 200,
      'unit': 'g',
      'kcal': 700,
      'protein': 24,
      'carbs': 140,
      'fat': 4,
    },
    {
      'text': 'Salz nach Geschmack',
      'amount': 0,
      'unit': 'g',
      'kcal': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    },
    {
      'text': '100 ml Milch',
      'amount': 100,
      'unit': 'ml',
      'kcal': 50,
      'protein': 3,
      'carbs': 5,
      'fat': 2,
    },
  ],
  'instructions': ['Cook pasta', ' Add sauce '],
  'image_prompt': 'tomato pasta on a plate',
};

void main() {
  const parser = AiChefRecipeResponseParser();

  test('parse reads the whole recipe idea', () {
    final idea = parser.parse(jsonEncode(_answer()), now: _now);
    final recipe = idea.recipe;

    expect(idea.imagePrompt, 'tomato pasta on a plate');
    expect(recipe.id, '');
    expect(recipe.name, 'Tomato Pasta');
    expect(recipe.totalPortions, 2);
    expect(recipe.remainingPortions, 2);
    expect(recipe.createdAt, _now);
    expect(recipe.updatedAt, _now);
    expect(recipe.components, isEmpty);
    expect(recipe.recipeIngredients, [
      '200 g pasta',
      'Salz nach Geschmack',
      '100 ml Milch',
    ]);
    expect(recipe.recipeInstructions, ['Cook pasta', 'Add sauce']);
  });

  test(
    'parse sums the ingredient lines into the dish and divides by the portions',
    () {
      final recipe = parser.parse(jsonEncode(_answer()), now: _now).recipe;

      expect(recipe.totalKcal, 750);
      expect(recipe.totalProtein, 27);
      expect(recipe.totalCarbs, 145);
      expect(recipe.totalFat, 6);
      final estimate = recipe.recipeEstimate!;
      expect(estimate.kcal, 375);
      expect(estimate.protein, 13.5);
      expect(estimate.carbs, 72.5);
      expect(estimate.fat, 3);
      expect(estimate.portions, 2);
      expect(estimate.createdAt, _now);
      expect(estimate.linesKey, recipeLinesKey(recipe.recipeIngredients));
    },
  );

  test('parse keeps the nutrition of each ingredient line', () {
    final lines = parser
        .parse(jsonEncode(_answer()), now: _now)
        .recipe
        .recipeEstimate!
        .lines!;

    expect(lines, hasLength(3));
    expect(lines.first.kcal, 700);
    expect(lines.first.protein, 24);
    expect(lines.first.carbs, 140);
    expect(lines.first.fat, 4);
    expect(lines.last.kcal, 50);
  });

  test('parse gives a weight per line, none for an amount of 0', () {
    final weights = parser
        .parse(jsonEncode(_answer()), now: _now)
        .recipe
        .recipeLineWeights;

    expect(weights.keys, ['200 g pasta', '100 ml Milch']);
    expect(weights['200 g pasta']!.amount, 200);
    expect(weights['200 g pasta']!.unit, RecipeLineWeightUnit.gram);
    expect(weights['200 g pasta']!.source, RecipeLineWeightSource.ai);
    expect(weights['100 ml Milch']!.unit, RecipeLineWeightUnit.milliliter);
  });

  test('parse takes the dish from the lines, not from the answer', () {
    final json = _answer()
      ..['portions'] = 2
      ..['kcal'] = 500;
    json['ingredients'] = [
      for (final kcal in [1000, 400])
        {
          'text': 'line $kcal',
          'amount': 100,
          'unit': 'g',
          'kcal': kcal,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        },
    ];

    final recipe = parser.parse(jsonEncode(json), now: _now).recipe;

    expect(recipe.totalKcal, 1400);
    expect(recipe.recipeEstimate!.kcal, 700);
  });

  test('parse accepts an amount of 0 with an empty unit, without a weight', () {
    final json = _answer();
    final salt = (json['ingredients']! as List).cast<Map<String, Object?>>()[1]
      ..['unit'] = '';

    final recipe = parser.parse(jsonEncode(json), now: _now).recipe;

    expect(recipe.recipeLineWeights.containsKey(salt['text']), isFalse);
    expect(recipe.recipeEstimate!.lines, hasLength(3));
  });

  test('parse gives no weight to a line text that occurs twice', () {
    final json = _answer();
    json['ingredients'] = [
      for (final amount in [20, 10])
        {
          'text': 'Wasser',
          'amount': amount,
          'unit': 'ml',
          'kcal': amount,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        },
      {
        'text': '200 g pasta',
        'amount': 200,
        'unit': 'g',
        'kcal': 700,
        'protein': 24,
        'carbs': 140,
        'fat': 4,
      },
    ];

    final recipe = parser.parse(jsonEncode(json), now: _now).recipe;

    expect(recipe.recipeLineWeights.keys, ['200 g pasta']);
    expect(recipe.recipeEstimate!.lines, hasLength(3));
    expect(recipe.recipeEstimate!.lines!.first.kcal, 20);
    expect(recipe.recipeEstimate!.lines![1].kcal, 10);
  });

  group('parse throws a FormatException for', () {
    void rejects(String name, void Function(Map<String, Object?>) change) {
      test(name, () {
        final json = _answer();
        change(json);
        expect(
          () => parser.parse(jsonEncode(json), now: _now),
          throwsFormatException,
        );
      });
    }

    List<Map<String, Object?>> lines(Map<String, Object?> json) =>
        (json['ingredients']! as List).cast<Map<String, Object?>>();

    test('text that is not json', () {
      expect(() => parser.parse('not json', now: _now), throwsFormatException);
    });
    test('a fenced answer', () {
      expect(
        () => parser.parse('```json\n${jsonEncode(_answer())}\n```', now: _now),
        throwsFormatException,
      );
    });
    test('an answer that is not an object', () {
      expect(() => parser.parse('[]', now: _now), throwsFormatException);
    });
    for (final key in [
      'name',
      'portions',
      'ingredients',
      'instructions',
      'image_prompt',
    ]) {
      rejects('a missing $key', (json) => json.remove(key));
    }
    rejects('a blank name', (json) => json['name'] = '  ');
    rejects('a text for portions', (json) => json['portions'] = '2');
    rejects('0 portions', (json) => json['portions'] = 0);
    rejects('negative portions', (json) => json['portions'] = -1);
    rejects('an amount above 0 with an empty unit', (json) {
      lines(json).first['unit'] = '';
    });
    rejects('no ingredients', (json) => json['ingredients'] = <Object?>[]);
    rejects('an ingredient that is no object', (json) {
      json['ingredients'] = ['200 g pasta'];
    });
    rejects('a blank line text', (json) => lines(json).first['text'] = ' ');
    rejects(
      'a negative line amount',
      (json) => lines(json).first['amount'] = -5,
    );
    rejects('a line amount that is no integer', (json) {
      lines(json).first['amount'] = '200';
    });
    rejects('an unknown line unit', (json) => lines(json).first['unit'] = 'kg');
    rejects('a negative line fat', (json) => lines(json).first['fat'] = -1);
    rejects('a missing line kcal', (json) => lines(json).first.remove('kcal'));
    rejects('a step that is no text', (json) {
      json['instructions'] = ['Cook', 3];
    });
    rejects('a blank step', (json) => json['instructions'] = ['Cook', ' ']);
  });

  test('parse accepts no steps', () {
    final json = _answer()..['instructions'] = <Object?>[];

    expect(
      parser.parse(jsonEncode(json), now: _now).recipe.recipeInstructions,
      isEmpty,
    );
  });
}
