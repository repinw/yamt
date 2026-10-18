import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_check_save_service.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';

import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  final recipe = preparedMealTestData(id: 'stew');

  ({
    IngredientCheckSaveService service,
    FakePreparedMealTemplateRepository templates,
    FakeShoppingListRepository list,
  })
  start() {
    final templates = FakePreparedMealTemplateRepository(templates: [recipe]);
    final list = FakeShoppingListRepository();
    addTearDown(list.dispose);
    return (
      service: IngredientCheckSaveService(
        templates: templates,
        shopping: ShoppingListNamesService(list),
        clock: () => now,
      ),
      templates: templates,
      list: list,
    );
  }

  Future<void> save(IngredientCheckSaveService service, List<String> steps) =>
      service.save(
        recipe: recipe,
        assignments: {
          '200 g Reis': ['rice'],
        },
        ignored: const ['Salz'],
        onList: const ['1 Zwiebel'],
        onRecipeSaved: () => steps.add('recipe'),
      );

  Matcher failure({required bool recipeSaved}) => throwsA(
    isA<IngredientCheckSaveFailure>().having(
      (failure) => failure.recipeSaved,
      'recipeSaved',
      recipeSaved,
    ),
  );

  test('saves the recipe, then the shopping list', () async {
    final (:service, :templates, :list) = start();
    final steps = <String>[];

    await save(service, steps);

    final saved = templates.templates.single;
    expect(saved.recipeIngredientAssignments, {
      '200 g Reis': ['rice'],
    });
    expect(saved.ignoredRecipeIngredients, ['Salz']);
    expect(saved.updatedAt, now);
    expect(steps, ['recipe']);
    expect(list.savedItems.map((item) => item.name), ['1 Zwiebel']);
  });

  test('a failed recipe save stops before anything changed', () async {
    final (:service, :templates, :list) = start();
    templates.failWrites = true;
    final steps = <String>[];

    await expectLater(save(service, steps), failure(recipeSaved: false));
    expect(steps, isEmpty);
    expect(list.savedItems, isEmpty);
  });

  test('a failed list says the recipe is saved', () async {
    final (:service, :templates, :list) = start();
    list.saveAllShouldThrow = true;
    final steps = <String>[];

    await expectLater(save(service, steps), failure(recipeSaved: true));
    expect(steps, ['recipe']);
    expect(templates.templates.single.ignoredRecipeIngredients, ['Salz']);
  });
}
