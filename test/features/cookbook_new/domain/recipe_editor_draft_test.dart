import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

final _now = DateTime.utc(2026, 11, 7, 12);
final _earlier = DateTime.utc(2026, 11);

RecipeLineWeight _ai(int grams) => RecipeLineWeight(
  amount: grams,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.ai,
);

RecipeLineWeight _typed(int grams) => RecipeLineWeight(
  amount: grams,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.user,
);

PreparedMeal _recipe({
  int totalPortions = 2,
  List<String> ingredients = const ['1 Zwiebel', '200 g Mehl'],
  Map<String, RecipeLineWeight> weights = const {},
  Map<String, List<String>> assignments = const {},
}) => PreparedMeal(
  id: 'recipe-1',
  name: 'Brot',
  totalPortions: totalPortions,
  remainingPortions: totalPortions,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _earlier,
  updatedAt: _earlier,
  components: const [],
  recipeIngredients: ingredients,
  recipeInstructions: const ['Kneten', 'Backen'],
  recipeLineWeights: weights,
  recipeIngredientAssignments: assignments,
);

ScannedIngredientList _scanned({
  String? title,
  int? servings,
  List<String> ingredients = const [],
  List<String> steps = const [],
}) => ScannedIngredientList(
  title: title,
  servings: servings,
  ingredients: ingredients,
  steps: steps,
);

List<String> _texts(List<RecipeEditorLine> lines) => [
  for (final line in lines) line.text,
];

void main() {
  group('RecipeEditorDraft', () {
    test('starts empty for two portions and cannot be saved', () {
      const draft = RecipeEditorDraft();

      expect(draft.original, isNull);
      expect(draft.name, '');
      expect(draft.portions, 2);
      expect(draft.isEmpty, isTrue);
      expect(draft.canSave, isFalse);
    });

    group('fromRecipe', () {
      test('takes name, portions, lines with their saved text and weight', () {
        final recipe = _recipe(weights: {'1 Zwiebel': _ai(150)});

        final draft = RecipeEditorDraft.fromRecipe(recipe);

        expect(draft.original, recipe);
        expect(draft.name, 'Brot');
        expect(draft.portions, 2);
        expect(_texts(draft.ingredients), ['1 Zwiebel', '200 g Mehl']);
        expect(draft.ingredients.first.saved, '1 Zwiebel');
        expect(draft.ingredients.first.weight, _ai(150));
        expect(draft.ingredients.last.weight, isNull);
        expect(_texts(draft.steps), ['Kneten', 'Backen']);
        expect(draft.steps.every((step) => step.saved == null), isTrue);
        expect(draft.isEmpty, isFalse);
      });

      test('a recipe without portions starts at one', () {
        expect(
          RecipeEditorDraft.fromRecipe(_recipe(totalPortions: 0)).portions,
          1,
        );
      });
    });

    test('canSave needs a name and an ingredient', () {
      final ready = const RecipeEditorDraft().copyWith(name: 'Suppe');
      final withLine = ready.withAddedLines(.ingredients, ['Salz']);

      expect(ready.canSave, isFalse);
      expect(withLine.canSave, isTrue);
      expect(withLine.copyWith(name: '  ').canSave, isFalse);
      // Steps alone are no recipe.
      expect(ready.withAddedLines(.steps, ['Kochen']).canSave, isFalse);
    });

    group('portionsSetFrom', () {
      test('is null while an editor without a count stays at the default', () {
        expect(const RecipeEditorDraft().portionsSetFrom(null), isNull);
      });

      test('is the count the cook stepped to', () {
        expect(const RecipeEditorDraft(portions: 3).portionsSetFrom(null), 3);
        expect(const RecipeEditorDraft(portions: 7).portionsSetFrom(6), 7);
        expect(const RecipeEditorDraft().portionsSetFrom(6), 2);
      });

      test('is the count the editor opened with while it stays there', () {
        expect(const RecipeEditorDraft(portions: 6).portionsSetFrom(6), 6);
      });
    });

    group('hasChanges', () {
      final saved = RecipeEditorDraft.fromRecipe(
        _recipe(weights: {'1 Zwiebel': _ai(150)}),
      );
      final photo = Uint8List.fromList([1, 2, 3]);

      test('a new draft has none until something is entered', () {
        const draft = RecipeEditorDraft();

        expect(draft.hasChanges, isFalse);
        expect(draft.copyWith(name: 'Suppe').hasChanges, isTrue);
        expect(draft.copyWith(portions: 4).hasChanges, isTrue);
        expect(draft.copyWith(photo: photo).hasChanges, isTrue);
        expect(draft.withAddedLines(.ingredients, ['Salz']).hasChanges, isTrue);
        expect(draft.withAddedLines(.steps, ['Kochen']).hasChanges, isTrue);
      });

      test('spaces in the name and the kept link are nothing to lose', () {
        const draft = RecipeEditorDraft();

        expect(draft.copyWith(name: '  ').hasChanges, isFalse);
        expect(
          draft.copyWith(recipeUrl: 'https://example.com/suppe').hasChanges,
          isFalse,
        );
      });

      test('a saved recipe has none as it opened', () {
        expect(saved.hasChanges, isFalse);
        expect(saved.copyWith(name: 'Brot ').hasChanges, isFalse);
      });

      test('a saved recipe counts its name, portions, photo, and lines', () {
        expect(saved.copyWith(name: 'Bauernbrot').hasChanges, isTrue);
        expect(saved.copyWith(portions: 5).hasChanges, isTrue);
        expect(saved.copyWith(photo: photo).hasChanges, isTrue);
        expect(
          saved.withLine(.ingredients, 0, '2 Zwiebeln').hasChanges,
          isTrue,
        );
        expect(saved.withoutLine(.steps, 0).hasChanges, isTrue);
        expect(saved.withAddedLines(.steps, ['Ruhen']).hasChanges, isTrue);
      });

      test('a line changed back is nothing to lose', () {
        final back = saved
            .withLine(.ingredients, 1, '300 g Mehl')
            .withLine(.ingredients, 1, '200 g Mehl');

        expect(back.hasChanges, isFalse);
      });
    });

    test('isEmpty looks at both lists', () {
      const draft = RecipeEditorDraft();

      expect(draft.withAddedLines(.steps, ['Kochen']).isEmpty, isFalse);
      expect(draft.withAddedLines(.ingredients, ['Salz']).isEmpty, isFalse);
    });

    group('lines', () {
      test('withAddedLines trims and leaves empty texts out', () {
        final draft = const RecipeEditorDraft()
            .withAddedLines(.ingredients, [' Mehl ', '', '   '])
            .withAddedLines(.ingredients, ['Salz']);

        expect(_texts(draft.ingredients), ['Mehl', 'Salz']);
        expect(draft.steps, isEmpty);
        expect(draft.ingredients.every((line) => line.saved == null), isTrue);
      });

      test('withLine rewrites a line and keeps its saved text and weight', () {
        final draft = RecipeEditorDraft.fromRecipe(
          _recipe(weights: {'1 Zwiebel': _typed(120)}),
        ).withLine(.ingredients, 0, '  2 Zwiebeln ');

        final line = draft.ingredients.first;
        expect(line.text, '2 Zwiebeln');
        expect(line.saved, '1 Zwiebel');
        expect(line.weight, _typed(120));
        expect(_texts(draft.ingredients), ['2 Zwiebeln', '200 g Mehl']);
      });

      test('withLine with an empty text removes the line', () {
        final draft = RecipeEditorDraft.fromRecipe(_recipe())
            .withLine(.steps, 0, '  ');

        expect(_texts(draft.steps), ['Backen']);
      });

      test('withoutLine removes the line of that section only', () {
        final draft = RecipeEditorDraft.fromRecipe(_recipe())
            .withoutLine(.ingredients, 1);

        expect(_texts(draft.ingredients), ['1 Zwiebel']);
        expect(_texts(draft.steps), ['Kneten', 'Backen']);
      });

      test('withRestoredLine puts a removed line back where it stood, with '
          'its weight', () {
        final opened = RecipeEditorDraft.fromRecipe(
          _recipe(weights: {'1 Zwiebel': _typed(120)}),
        );
        final removed = opened.ingredients.first;

        final restored = opened
            .withoutLine(.ingredients, 0)
            .withRestoredLine(.ingredients, 0, removed);

        expect(_texts(restored.ingredients), ['1 Zwiebel', '200 g Mehl']);
        expect(restored.ingredients.first.weight, _typed(120));
        expect(restored.hasChanges, isFalse);
      });

      test('withRestoredLine goes last when the list is shorter by now', () {
        final opened = RecipeEditorDraft.fromRecipe(_recipe());
        final removed = opened.steps.last;

        final restored = opened
            .withoutLine(.steps, 1)
            .withoutLine(.steps, 0)
            .withRestoredLine(.steps, 1, removed);

        expect(_texts(restored.steps), ['Backen']);
        expect(_texts(restored.ingredients), ['1 Zwiebel', '200 g Mehl']);
      });

      test('a line whose text changed drops its saved weight, an unchanged '
          'line keeps it', () {
        final draft = RecipeEditorDraft.fromRecipe(
          _recipe(weights: {'1 Zwiebel': _typed(120), '200 g Mehl': _ai(200)}),
        ).withLine(.ingredients, 0, '2 Zwiebeln');

        expect(draft.ingredients.first.keptWeight, isNull);
        expect(draft.ingredients.last.keptWeight, _ai(200));
      });

      test('a line changed back keeps its weight again', () {
        final draft =
            RecipeEditorDraft.fromRecipe(
                  _recipe(weights: {'1 Zwiebel': _typed(120)}),
                )
                .withLine(.ingredients, 0, '2 Zwiebeln')
                .withLine(.ingredients, 0, '1 Zwiebel');

        expect(draft.ingredients.first.keptWeight, _typed(120));
      });
    });

    group('withScan', () {
      test('fills an empty or blank name and takes the servings', () {
        final draft = const RecipeEditorDraft()
            .copyWith(name: '  ')
            .withScan(
              _scanned(title: 'Brot', servings: 6, ingredients: ['Mehl']),
            );

        expect(draft.name, 'Brot');
        expect(draft.portions, 6);
        expect(_texts(draft.ingredients), ['Mehl']);
      });

      test('keeps a typed name and the portions without servings', () {
        final draft = const RecipeEditorDraft()
            .copyWith(name: 'Mein Brot', portions: 3)
            .withScan(_scanned(title: 'Brot', servings: 0));

        expect(draft.name, 'Mein Brot');
        expect(draft.portions, 3);
      });

      test('a scan without a title leaves the name empty', () {
        expect(const RecipeEditorDraft().withScan(_scanned()).name, '');
      });

      test('appends ingredients and steps after the lines there are', () {
        final draft = const RecipeEditorDraft()
            .withAddedLines(.ingredients, ['Salz'])
            .withAddedLines(.steps, ['Rühren'])
            .withScan(
              _scanned(ingredients: ['Mehl', 'Eier'], steps: ['Backen']),
            );

        expect(_texts(draft.ingredients), ['Salz', 'Mehl', 'Eier']);
        expect(_texts(draft.steps), ['Rühren', 'Backen']);
      });
    });

    group('withPastedText', () {
      test(
        'lines up to the first empty line are ingredients, the rest steps',
        () {
          final draft = const RecipeEditorDraft().withPastedText(
            '200 g Mehl\nSalz\n\nMischen\nBacken\n',
          );

          expect(_texts(draft.ingredients), ['200 g Mehl', 'Salz']);
          expect(_texts(draft.steps), ['Mischen', 'Backen']);
        },
      );

      test('text without an empty line is all ingredients', () {
        final draft = const RecipeEditorDraft().withPastedText('Mehl\nSalz');

        expect(_texts(draft.ingredients), ['Mehl', 'Salz']);
        expect(draft.steps, isEmpty);
      });

      test('a step loses its number or bullet and windows lines work', () {
        final draft = const RecipeEditorDraft().withPastedText(
          'Mehl\r\n\r\n1. Mischen\r\n2) Kneten\r\n- Backen\r\n• Essen\r\n'
          '* Fertig\r\n10. Aufräumen',
        );

        expect(_texts(draft.ingredients), ['Mehl']);
        expect(_texts(draft.steps), [
          'Mischen',
          'Kneten',
          'Backen',
          'Essen',
          'Fertig',
          'Aufräumen',
        ]);
      });

      test('the title becomes the name and the servings the portions', () {
        final draft = const RecipeEditorDraft().withPastedText(
          'Rezept: Brot – 6 Portionen\n\nZutaten\n- Mehl\n\nSchritte\n'
          '1. Backen',
        );

        expect(draft.name, 'Brot');
        expect(draft.portions, 6);
        expect(_texts(draft.ingredients), ['Mehl']);
        expect(_texts(draft.steps), ['Backen']);
      });

      test('keeps a name that is there and the portions without servings', () {
        final draft = const RecipeEditorDraft()
            .copyWith(name: 'Mein Brot', portions: 3)
            .withPastedText('Brot\n\nMehl\n\nBacken\nEssen');

        expect(draft.name, 'Mein Brot');
        expect(draft.portions, 3);
        expect(_texts(draft.ingredients), ['Mehl']);
      });

      test('adds after what is there', () {
        final draft = const RecipeEditorDraft()
            .withAddedLines(.ingredients, ['Salz'])
            .withPastedText('Mehl');

        expect(_texts(draft.ingredients), ['Salz', 'Mehl']);
      });
    });

    group('newRecipe', () {
      test('is the draft without id, made now, with the photo id and link', () {
        final draft = const RecipeEditorDraft()
            .copyWith(
              name: '  Suppe ',
              portions: 3,
              recipeUrl: 'https://example.com/suppe',
            )
            .withAddedLines(.ingredients, ['200 g Mehl', 'Salz'])
            .withAddedLines(.steps, ['Kochen']);

        final recipe = draft.newRecipe(now: _now, imageAssetId: 'photo-1');

        expect(recipe.id, '');
        expect(recipe.name, 'Suppe');
        expect(recipe.recipeUrl, 'https://example.com/suppe');
        expect(recipe.imageAssetId, 'photo-1');
        expect(recipe.recipeIngredients, ['200 g Mehl', 'Salz']);
        expect(recipe.recipeInstructions, ['Kochen']);
        expect(recipe.totalPortions, 3);
        expect(recipe.remainingPortions, 3);
        expect(recipe.components, isEmpty);
        expect(recipe.createdAt, _now);
        expect(recipe.updatedAt, _now);
        expect(recipe.recipeEstimate, isNull);
      });

      test('starts without weights: new lines have none until the next '
          'estimate', () {
        final draft = const RecipeEditorDraft()
            .copyWith(name: 'Suppe')
            .withAddedLines(.ingredients, ['1 Zwiebel', '2 Eier']);

        final recipe = draft.newRecipe(now: _now);

        expect(recipe.recipeLineWeights, isEmpty);
        expect(recipe.imageAssetId, isNull);
      });
    });

    group('editedRecipe', () {
      test('puts the draft onto the latest recipe and keeps what the editor '
          'does not show', () {
        final opened = _recipe(
          assignments: {
            '200 g Mehl': ['flour'],
          },
        );
        final estimate = RecipeEstimate(
          kcal: 400,
          protein: 10,
          carbs: 50,
          fat: 5,
          portions: 2,
          linesKey: recipeLinesKey(opened.recipeIngredients),
          createdAt: _earlier,
        );
        // Arrived after the editor opened.
        final latest = opened.copyWith(
          recipeEstimate: estimate,
          recipeIngredientAssignments: {
            '200 g Mehl': ['flour'],
            '1 Zwiebel': ['onion'],
          },
          ignoredRecipeIngredients: const ['1 Zwiebel'],
          imageUrl: 'https://example.com/old.jpg',
          recipeUrl: 'https://example.com/old',
        );
        final draft = RecipeEditorDraft.fromRecipe(opened)
            .copyWith(name: ' Bauernbrot ', portions: 4)
            .withLine(.ingredients, 1, '300 g Mehl')
            .withAddedLines(.steps, ['Abkühlen']);

        final edited = draft.editedRecipe(latest, now: _now);

        expect(edited.id, 'recipe-1');
        expect(edited.name, 'Bauernbrot');
        expect(edited.totalPortions, 4);
        expect(edited.remainingPortions, 4);
        expect(edited.recipeIngredients, ['1 Zwiebel', '300 g Mehl']);
        expect(edited.recipeInstructions, ['Kneten', 'Backen', 'Abkühlen']);
        expect(edited.updatedAt, _now);
        expect(edited.createdAt, _earlier);
        expect(edited.recipeEstimate, estimate);
        expect(edited.ignoredRecipeIngredients, ['1 Zwiebel']);
        // The renamed line takes its Vorrat item along.
        expect(edited.recipeIngredientAssignments, {
          '1 Zwiebel': ['onion'],
          '300 g Mehl': ['flour'],
        });
        expect(edited.imageUrl, 'https://example.com/old.jpg');
        expect(edited.recipeUrl, 'https://example.com/old');
      });

      test('a new photo replaces the photo and the image link, a new link '
          'the link', () {
        final latest = _recipe().copyWith(
          imageAssetId: 'old-photo',
          imageUrl: 'https://example.com/old.jpg',
          recipeUrl: 'https://example.com/old',
        );
        final draft = RecipeEditorDraft.fromRecipe(latest)
            .copyWith(recipeUrl: 'https://example.com/new');

        final edited = draft.editedRecipe(
          latest,
          now: _now,
          imageAssetId: 'new-photo',
        );

        expect(edited.imageAssetId, 'new-photo');
        expect(edited.imageUrl, isNull);
        expect(edited.recipeUrl, 'https://example.com/new');
      });

      test('a weight the editor left as it was takes the latest weight of '
          'its line', () {
        final opened = _recipe(weights: {'1 Zwiebel': _ai(100)});
        final latest = _recipe(
          weights: {'1 Zwiebel': _ai(150), '200 g Mehl': _ai(200)},
        );
        final draft = RecipeEditorDraft.fromRecipe(opened);

        final edited = draft.editedRecipe(latest, now: _now);

        // The estimate that arrived meanwhile is not lost.
        expect(edited.recipeLineWeights, {
          '1 Zwiebel': _ai(150),
          '200 g Mehl': _ai(200),
        });
      });

      test('a rewritten line loses its weight, typed or not', () {
        final opened = _recipe(
          weights: {'1 Zwiebel': _ai(100), '200 g Mehl': _typed(200)},
        );
        final draft = RecipeEditorDraft.fromRecipe(opened)
            .withLine(.ingredients, 0, '2 Zwiebeln')
            .withLine(.ingredients, 1, '300 g Mehl');

        final edited = draft.editedRecipe(opened, now: _now);

        expect(edited.recipeLineWeights, isEmpty);
      });

      test(
        'a line the cook removed takes its weight and Vorrat item along',
        () {
          final opened = _recipe(
            weights: {'1 Zwiebel': _typed(100)},
            assignments: {
              '1 Zwiebel': ['onion'],
            },
          );
          final draft = RecipeEditorDraft.fromRecipe(opened)
              .withoutLine(.ingredients, 0);

          final edited = draft.editedRecipe(opened, now: _now);

          expect(edited.recipeIngredients, ['200 g Mehl']);
          expect(edited.recipeLineWeights, isEmpty);
          expect(edited.recipeIngredientAssignments, isEmpty);
        },
      );
    });

    test('copyWith keeps the original, the lines, and the photo', () {
      final recipe = _recipe();
      final photo = Uint8List.fromList([1, 2, 3]);
      final draft = RecipeEditorDraft.fromRecipe(recipe).copyWith(photo: photo);

      final copy = draft.copyWith(name: 'Neu');

      expect(copy.original, recipe);
      expect(copy.photo, photo);
      expect(copy.ingredients, draft.ingredients);
      expect(copy.steps, draft.steps);
    });
  });
}
