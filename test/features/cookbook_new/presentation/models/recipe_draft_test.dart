import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_draft.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

import '../../../../support/prepared_meal_test_data.dart';

PreparedMeal _recipe({
  List<String> lines = const ['200 g Pasta', '100 g Tomaten'],
  bool estimated = false,
}) {
  final recipe = preparedMealTestData(
    id: 'pasta',
  ).copyWith(totalPortions: 2, components: const [], recipeIngredients: lines);
  return estimated
      ? recipe.copyWith(
          recipeEstimate: RecipeEstimate(
            kcal: 1,
            protein: 1,
            carbs: 1,
            fat: 1,
            portions: 2,
            linesKey: recipeLinesKey(lines),
            createdAt: DateTime.utc(2026, 11, 13),
          ),
        )
      : recipe;
}

void main() {
  group('RecipeDraft.waitsForEstimate', () {
    test('waits for a recipe with lines and no fitting estimate', () {
      expect(const RecipeDraft().waitsForEstimate(_recipe()), isTrue);
    });

    test('does not wait for a recipe whose estimate fits', () {
      expect(
        const RecipeDraft().waitsForEstimate(_recipe(estimated: true)),
        isFalse,
      );
    });

    test('does not wait for a Vorlage or a recipe without lines', () {
      expect(
        const RecipeDraft().waitsForEstimate(_recipe(lines: const [])),
        isFalse,
      );
    });

    test('stops waiting once the estimate of its key failed', () {
      final recipe = _recipe();
      final draft = RecipeDraft(failedEstimates: {recipe.recipeEstimateKey});

      expect(draft.waitsForEstimate(recipe), isFalse);
    });

    test('waits again for a new version of the lines or portions', () {
      final draft = RecipeDraft(failedEstimates: {_recipe().recipeEstimateKey});

      expect(
        draft.waitsForEstimate(_recipe(lines: const ['300 g Pasta'])),
        isTrue,
      );
      expect(
        draft.waitsForEstimate(_recipe().copyWith(totalPortions: 4)),
        isTrue,
      );
    });

    test('copyWith keeps the failed keys', () {
      final draft = const RecipeDraft(failedEstimates: {'a'})
          .copyWith(portions: 3);

      expect(draft.failedEstimates, {'a'});
      expect(draft.portions, 3);
    });
  });
}
