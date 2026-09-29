import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';

import '../../../support/prepared_meal_test_data.dart';

void main() {
  group('CookbookOverview.fromMeals', () {
    test('sorts templates without ingredients into Vorlagen', () {
      final template = preparedMealTestData(id: 'bowl');
      final recipe = preparedMealTestData(id: 'chili').copyWith(
        recipeIngredients: const ['500 g Beans', '1 Onion', '2 Peppers'],
        ignoredRecipeIngredients: const ['2 Peppers'],
      );

      final overview = CookbookOverview.fromMeals(
        savedTemplates: [template, recipe],
        meals: const [],
        isInStock: (food) => food.contains('Rice') || food.contains('Beans'),
      );

      expect(overview.templates.single.meal.id, 'bowl');
      expect(overview.templates.single.inStock, [true]);
      expect(overview.recipes.single.meal.id, 'chili');
      expect(overview.recipes.single.inStock, [true, false]);
      expect(overview.recipes.single.missingCount, 1);
    });

    test('lists meals with open rows and portions left, newest first', () {
      final older = preparedMealTestData(id: 'older').copyWith(
        pendingRecipeIngredients: const ['40 g Butter'],
        createdAt: DateTime.utc(2026, 9, 28),
      );
      final newer = preparedMealTestData(id: 'newer').copyWith(
        pendingRecipeIngredients: const ['200 g Rice'],
        createdAt: DateTime.utc(2026, 9, 29),
      );
      final complete = preparedMealTestData(id: 'complete');
      final eaten = preparedMealTestData(
        id: 'eaten',
        remainingPortions: 0,
      ).copyWith(pendingRecipeIngredients: const ['1 Egg']);

      final overview = CookbookOverview.fromMeals(
        savedTemplates: const [],
        meals: [older, complete, eaten, newer],
        isInStock: (_) => true,
      );

      expect(overview.openMeals.map((meal) => meal.id), ['newer', 'older']);
    });
  });
}
