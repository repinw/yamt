import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/application/cook_recipe_source.dart';

import '../../../helpers/fake_prepared_meal_template_repository.dart';

PreparedMeal _template(
  String id, {
  List<String> lines = const ['500 g Hackfleisch', 'Salz'],
}) => PreparedMeal(
  id: id,
  name: 'Eintopf $id',
  imageAssetId: 'photo',
  imageUrl: 'https://example.com/$id.jpg',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
  components: const [],
  recipeIngredients: lines,
  recipeInstructions: const ['Anbraten.', 'Köcheln.'],
);

void main() {
  group('cookRecipeTemplate', () {
    ProviderContainer containerWith(List<PreparedMeal> templates) {
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(templates: templates),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    // Holds the provider like the open page does.
    Future<PreparedMeal?> read(ProviderContainer container, String id) {
      final provider = cookRecipeTemplateProvider(id);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      return container.read(provider.future);
    }

    test('finds the recipe by id', () async {
      final container = containerWith([_template('a'), _template('b')]);

      final found = await read(container, 'b');

      expect(found?.id, 'b');
    });

    test('is null when the recipe is gone', () async {
      final container = containerWith([_template('a')]);

      expect(await read(container, 'x'), isNull);
    });

    test('a Vorlage without ingredient lines is not a recipe', () async {
      final container = containerWith([_template('a', lines: const [])]);

      expect(await read(container, 'a'), isNull);
    });
  });
}
