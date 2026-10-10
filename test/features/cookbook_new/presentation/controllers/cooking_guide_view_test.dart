import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

final _now = DateTime.utc(2026, 10, 10);

final _recipe = PreparedMeal(
  id: 'eggs',
  name: 'Rührei',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _now,
  updatedAt: _now,
  components: const <PreparedMealComponent>[],
  recipeIngredients: const ['4 Eier', '200 g Tomaten', 'Salz'],
  ignoredRecipeIngredients: const ['Salz'],
  recipeInstructions: const [
    'Tomaten halbieren.',
    'Eier verquirlen, mit Salz würzen. In die Pfanne geben.',
  ],
);

void main() {
  test('reads the recipe for the chosen portions, one sentence at a time, '
      'with the ingredients each names', () async {
    final container = ProviderContainer(
      overrides: [
        cookbookTemplatesProvider.overrideWith(
          (ref) => Stream.value([_recipe]),
        ),
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream.value(const <InventoryItem>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(recipeControllerProvider('eggs'), (_, _) {})
      ..read(recipeControllerProvider('eggs').notifier).setPortions(4);
    final provider = cookingGuideProvider('eggs', 'de');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    while (container.read(provider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    var guide = container.read(provider).requireValue!;
    expect(guide.portions, 4);
    expect(guide.justAdded, isEmpty);
    expect(guide.ingredients, ['8 Eier', '400 g Tomaten', 'Salz']);
    expect(guide.sentences.map((s) => (s.sentence.step, s.sentence.text)), [
      (1, 'Tomaten halbieren.'),
      (2, 'Eier verquirlen, mit Salz würzen.'),
      (2, 'In die Pfanne geben.'),
    ]);
    expect(guide.sentences.map((s) => s.ingredients), [
      ['400 g Tomaten'],
      ['8 Eier', 'Salz'],
      isEmpty,
    ]);

    container
        .read(recipeControllerProvider('eggs').notifier)
        .addSpoken(
          container.read(recipeViewProvider('eggs', 'de')).requireValue!,
          '50 g Feta',
        );
    guide = container.read(provider).requireValue!;
    expect(guide.justAdded, ['50 g Feta']);
    expect(guide.ingredients.last, '50 g Feta');
  });
}
