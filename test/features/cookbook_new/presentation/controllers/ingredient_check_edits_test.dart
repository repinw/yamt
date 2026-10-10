import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'ingredient_check_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'ingredient_check_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'ingredient_check_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_edits.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';

import '../../../shoppinglist/support/fake_shopping_list_repository.dart';

final _now = DateTime.utc(2026, 10, 10);

final _recipe = PreparedMeal(
  id: 'stew',
  name: 'Bauerntopf',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _now,
  updatedAt: _now,
  components: const <PreparedMealComponent>[],
  recipeIngredients: const ['500 g Hackfleisch', '3 Tomaten', 'Salz'],
  ignoredRecipeIngredients: const ['Salz'],
);

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  final saved = <PreparedMeal>[];

  /// Stands in for the template stream, which delivers what is saved.
  final templates = StreamController<List<PreparedMeal>>.broadcast();

  @override
  Future<bool> save(PreparedMeal template) async {
    saved.add(template);
    templates.add([template]);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container(
  _FakeTemplateRepository templates, {
  ShoppingListRepository? shopping,
}) {
  final list = FakeShoppingListRepository();
  addTearDown(list.dispose);
  addTearDown(templates.templates.close);
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) async* {
        yield [_recipe];
        yield* templates.templates.stream;
      }),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value([
          InventoryItem.create(
            id: 'mince',
            name: 'Hackfleisch',
            entryDate: _now,
            storeName: 'Store',
            quantity: 1,
            initialAmount: 2000,
            currentAmount: 2000,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ]),
      ),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      shoppingListRepositoryProvider.overrideWithValue(shopping ?? list),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(recipeControllerProvider('stew'), (_, _) {})
    ..listen(ingredientCheckControllerProvider('stew'), (_, _) {});
  return container;
}

Future<IngredientCheckView> _check(ProviderContainer container) async {
  final provider = ingredientCheckViewProvider('stew', 'de');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  await Future<void>.delayed(Duration.zero);
  while (container.read(provider).isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider).requireValue!;
}

IngredientCheckController _controller(ProviderContainer container) =>
    container.read(ingredientCheckControllerProvider('stew').notifier);

/// More meat for three portions, no tomatoes, and butter.
Future<IngredientCheckView> _change(ProviderContainer container) async {
  container.read(recipeControllerProvider('stew').notifier).setPortions(3);
  var check = await _check(container);
  _controller(container)
    ..setAmount(check.view, check.view.lines.first, 1200)
    ..remove(check.view, check.view.lines[1])
    ..add(check.view, '75 g Butter');
  return check = await _check(container);
}

void main() {
  test('changes are written for the recipe portions and shown for the '
      'chosen ones', () async {
    final container = _container(_FakeTemplateRepository());

    final check = await _change(container);

    expect(
      container.read(ingredientCheckControllerProvider('stew')).edits?.changed,
      {'500 g Hackfleisch': '800 g Hackfleisch', '3 Tomaten': null},
    );
    expect(check.view.recipe.recipeIngredients, [
      '800 g Hackfleisch',
      'Salz',
      '50 g Butter',
    ]);
    expect(check.view.lines.first.row.requirement?.amount, 1200);
    expect(check.view.lines.first.items.single.id, 'mince');
    expect(check.view.recipe.ignoredRecipeIngredients, ['Salz']);
    expect(check.view.changes.map((change) => (change.food, change.removed)), [
      ('Hackfleisch', false),
      ('Tomaten', true),
      ('Butter', false),
    ]);
  });

  test('changes for this time keep the saved recipe and go to the recipe '
      'page', () async {
    final templates = _FakeTemplateRepository();
    final container = _container(templates);
    final check = await _change(container);

    expect(
      await _controller(container).finish(check),
      IngredientCheckFinish.done,
    );

    final saved = templates.saved.single;
    expect(saved.recipeIngredients, _recipe.recipeIngredients);
    expect(saved.recipeIngredientAssignments, {
      '500 g Hackfleisch': ['mince'],
    });
    expect(container.read(recipeControllerProvider('stew')).edits.changed, {
      '500 g Hackfleisch': '800 g Hackfleisch',
      '3 Tomaten': null,
    });
  });

  test('saved changes go into the recipe', () async {
    final templates = _FakeTemplateRepository();
    final container = _container(templates);
    final check = await _change(container);
    _controller(container).setSaveEdits(save: true);

    await _controller(container).finish(await _check(container));

    final saved = templates.saved.single;
    expect(saved.recipeIngredients, [
      '800 g Hackfleisch',
      'Salz',
      '50 g Butter',
    ]);
    expect(saved.recipeIngredientAssignments, {
      '800 g Hackfleisch': ['mince'],
    });
    expect(check.draft.saveEdits, isFalse);
    expect(
      container.read(recipeControllerProvider('stew')).edits,
      isA<RecipeEdits>().having((edits) => edits.isEmpty, 'isEmpty', isTrue),
    );
  });

  test('typing the old amount again undoes the change', () async {
    final container = _container(_FakeTemplateRepository());
    var check = await _check(container);
    _controller(container).setAmount(check.view, check.view.lines.first, 600);
    check = await _check(container);
    _controller(container).setAmount(check.view, check.view.lines.first, 500);

    expect(
      container.read(ingredientCheckControllerProvider('stew')).edits?.changed,
      isEmpty,
    );
  });

  test('a choice stays when the amount changes', () async {
    final templates = _FakeTemplateRepository();
    final container = _container(templates);
    var check = await _check(container);
    _controller(container)
        .choose(check.view.lines.first.key, IngredientCheckChoice.ignore);
    _controller(container).setAmount(check.view, check.view.lines.first, 800);
    check = await _check(container);

    expect(check.view.lines.first.ingredient, '800 g Hackfleisch');
    expect(
      check.draft.choiceOf(check.view.lines.first),
      IngredientCheckChoice.ignore,
    );
    await _controller(container).finish(check);
    expect(templates.saved.single.ignoredRecipeIngredients, [
      'Salz',
      '500 g Hackfleisch',
    ]);
  });

  test('an amount for other portions comes back exactly', () async {
    final container = _container(_FakeTemplateRepository());
    container.read(recipeControllerProvider('stew').notifier).setPortions(3);
    var check = await _check(container);
    // 3 Tomaten for 2 portions are 5 for 3; the cook wants 4.
    _controller(container).setAmount(check.view, check.view.lines[1], 4);
    check = await _check(container);

    expect(check.view.lines[1].ingredient, '2,67 Tomaten');
    expect(check.view.lines[1].row.requirement?.amount, 4);
  });

  test('an added ingredient for other portions keeps a small amount', () async {
    final container = _container(_FakeTemplateRepository());
    container.read(recipeControllerProvider('stew').notifier).setPortions(8);
    var check = await _check(container);
    _controller(container).add(check.view, '1 Ei');
    check = await _check(container);

    expect(check.view.lines.last.ingredient, '0,25 Ei');
    expect(check.view.lines.last.row.requirement?.amount, 1);
  });

  test('a second try after a failed list does not add twice', () async {
    final templates = _FakeTemplateRepository();
    final shopping = FakeShoppingListRepository()..saveAllShouldThrow = true;
    addTearDown(shopping.dispose);
    final container = _container(templates, shopping: shopping);
    var check = await _change(container);
    _controller(container).setSaveEdits(save: true);

    expect(
      await _controller(container).finish(await _check(container)),
      IngredientCheckFinish.listFailed,
    );
    check = await _check(container);
    await _controller(container).finish(check);

    expect(templates.saved.last.recipeIngredients, [
      '800 g Hackfleisch',
      'Salz',
      '50 g Butter',
    ]);
  });

  test('an added ingredient for this time takes its choice to the recipe '
      'page', () async {
    final container = _container(_FakeTemplateRepository());
    var check = await _check(container);
    _controller(container)
      ..add(check.view, '1 Dose Kokosmilch')
      ..add(check.view, '75 g Butter');
    check = await _check(container);
    final milk = check.view.lines[3];
    final butter = check.view.lines[4];
    _controller(container)
      ..choose(milk.key, IngredientCheckChoice.ignore)
      ..choose(butter.key, IngredientCheckChoice.cart);

    await _controller(container).finish(await _check(container));

    final draft = container.read(recipeControllerProvider('stew'));
    expect(draft.edits.added, {butter.key: '75 g Butter'});
    expect(draft.picks, containsPair(butter.key, null));
    expect(draft.picks.containsKey(milk.key), isFalse);
  });

  test('one ingredient has to stay', () async {
    final container = _container(_FakeTemplateRepository());
    var check = await _check(container);
    _controller(container).remove(check.view, check.view.lines[1]);
    check = await _check(container);

    expect(check.view.canRemove, isFalse);
    _controller(container).remove(check.view, check.view.activeLines.single);
    check = await _check(container);
    expect(check.view.activeLines, hasLength(1));
  });

  test('"Nein" drops the changes of this check', () async {
    final container = _container(_FakeTemplateRepository());
    final check = await _change(container);
    _controller(container).discardEdits();

    expect((await _check(container)).view.recipe.recipeIngredients, [
      ...check.view.saved.recipeIngredients,
    ]);
  });

  test(
    'an ingredient added after "Nein" starts without the old choices',
    () async {
      final container = _container(_FakeTemplateRepository());
      var check = await _check(container);
      _controller(container).add(check.view, '75 g Butter');
      check = await _check(container);
      _controller(container)
        ..choose(check.view.lines.last.key, IngredientCheckChoice.ignore)
        ..discardEdits()
        ..add(check.view, '200 g Erbsen');
      check = await _check(container);

      expect(check.view.lines.last.ingredient, '200 g Erbsen');
      expect(
        check.draft.choiceOf(check.view.lines.last),
        IngredientCheckChoice.cart,
      );
    },
  );

  test('a fraction added for fewer portions is scaled up', () async {
    final container = _container(_FakeTemplateRepository());
    container.read(recipeControllerProvider('stew').notifier).setPortions(1);
    var check = await _check(container);
    _controller(container).add(check.view, '1/2 Zitrone');
    check = await _check(container);

    expect(check.view.lines.last.ingredient, '1 Zitrone');
  });

  test('an added ingredient named like an ignored one is cooked', () async {
    final container = _container(_FakeTemplateRepository());
    var check = await _check(container);
    _controller(container).add(check.view, 'Salz');
    check = await _check(container);

    expect(check.view.activeLines.last.ingredient, 'Salz');
    expect(check.view.activeLines.last.isAdded, isTrue);
  });
}
