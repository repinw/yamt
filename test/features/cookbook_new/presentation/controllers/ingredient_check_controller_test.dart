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
    'recipe_view.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';

import '../../../shoppinglist/support/fake_shopping_list_repository.dart';

final _now = DateTime.utc(2026, 10, 9);

InventoryItem _item(String id, String name, int amount) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: _now,
  storeName: 'Store',
  quantity: 1,
  initialAmount: amount,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
);

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
  recipeIngredients: const [
    '500 g Hackfleisch',
    '600 g Karotten',
    '1 Zwiebel',
    'Salz',
  ],
  ignoredRecipeIngredients: const ['Salz'],
);

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new({this.succeeds = true, this.gate});

  final bool succeeds;
  final Completer<void>? gate;
  final saved = <PreparedMeal>[];

  @override
  Future<bool> save(PreparedMeal template) async {
    await gate?.future;
    saved.add(template);
    return succeeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container(
  _FakeTemplateRepository templates, {
  List<InventoryItem>? items,
  FakeShoppingListRepository? shopping,
}) {
  final list = shopping ?? FakeShoppingListRepository();
  addTearDown(list.dispose);
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value([_recipe])),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(
          items ??
              [
                _item('mince', 'Hackfleisch', 2000),
                _item('carrots', 'Karotten', 400),
              ],
        ),
      ),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      shoppingListRepositoryProvider.overrideWithValue(list),
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

List<String> _ingredients(List<RecipeIngredientLine> lines) => [
  for (final line in lines) line.ingredient,
];

void main() {
  test(
    'sorts the ingredients into found, missing, and missing parts',
    () async {
      final container = _container(_FakeTemplateRepository());
      final check = await _check(container);

      expect(_ingredients(check.found), [
        '500 g Hackfleisch',
        '600 g Karotten',
      ]);
      expect(_ingredients(check.missing), ['1 Zwiebel']);
      expect(_ingredients(check.rests), ['600 g Karotten']);
      expect(check.rests.single.restLabel, '200 g Karotten');
      expect(check.fromStock, ['500 g Hackfleisch', '400 g Karotten']);
      expect(check.onList, ['1 Zwiebel', '200 g Karotten']);
    },
  );

  test(
    'finish saves the Vorrat items and the ignored ones on the recipe',
    () async {
      final templates = _FakeTemplateRepository();
      final container = _container(templates);
      _controller(container).choose('1 Zwiebel', IngredientCheckChoice.ignore);

      expect(
        await _controller(container).finish(await _check(container)),
        IngredientCheckFinish.done,
      );

      final saved = templates.saved.single;
      expect(saved.id, 'stew');
      expect(saved.recipeIngredientAssignments, {
        '500 g Hackfleisch': ['mince'],
        '600 g Karotten': ['carrots'],
      });
      expect(saved.ignoredRecipeIngredients, ['Salz', '1 Zwiebel']);
    },
  );

  test(
    'a found ingredient put on the list skips the Vorrat this time',
    () async {
      final templates = _FakeTemplateRepository();
      final container = _container(templates);
      _controller(container)
          .choose('500 g Hackfleisch', IngredientCheckChoice.cart);

      final check = await _check(container);
      expect(check.onList, contains('500 g Hackfleisch'));
      expect(
        await _controller(container).finish(check),
        IngredientCheckFinish.done,
      );

      expect(
        templates.saved.single.recipeIngredientAssignments.keys,
        isNot(contains('500 g Hackfleisch')),
      );
      expect(
        container
            .read(recipeControllerProvider('stew'))
            .picks['500 g Hackfleisch'],
        isNull,
      );
    },
  );

  test('a food that Hab ich added keeps its ingredient with the missing '
      'ones', () async {
    final templates = _FakeTemplateRepository();
    final container = _container(
      templates,
      items: [
        _item('mince', 'Hackfleisch', 2000),
        _item('carrots', 'Karotten', 400),
        _item('first-onion', 'Zwiebel', 1),
        _item('onion', 'Zwiebel', 1),
        _item('more-carrots', 'Karotten Bio', 300),
      ],
    );
    _controller(container)
      ..have('1 Zwiebel', 'first-onion')
      ..have('1 Zwiebel', 'onion')
      ..have('600 g Karotten', 'more-carrots', rest: true);

    final check = await _check(container);
    expect(_ingredients(check.missing), ['1 Zwiebel']);
    expect(check.found[1].items.map((item) => item.id), ['carrots']);
    expect(
      await _controller(container).finish(check),
      IngredientCheckFinish.done,
    );

    expect(templates.saved.single.recipeIngredientAssignments, {
      '500 g Hackfleisch': ['mince'],
      '600 g Karotten': ['carrots', 'more-carrots'],
      '1 Zwiebel': ['onion'],
    });
  });

  test('a pick of none moves the ingredient to the missing ones', () async {
    final container = _container(_FakeTemplateRepository());
    _controller(container)
      ..choose('500 g Hackfleisch', IngredientCheckChoice.use)
      ..pick('500 g Hackfleisch', null);

    final check = await _check(container);

    expect(_ingredients(check.missing), ['500 g Hackfleisch', '1 Zwiebel']);
    expect(
      check.draft.choiceOf(check.missing.first),
      IngredientCheckChoice.cart,
    );
    expect(container.read(recipeControllerProvider('stew')).picks, isEmpty);
  });

  test('finish puts what the cook is short of on the shopping list', () async {
    final shopping = FakeShoppingListRepository();
    final container = _container(_FakeTemplateRepository(), shopping: shopping);

    await _controller(container).finish(await _check(container));

    expect(shopping.savedItems.map((item) => item.name), [
      '1 Zwiebel',
      '200 g Karotten',
    ]);
  });

  test('a failed shopping list keeps the saved recipe', () async {
    final templates = _FakeTemplateRepository();
    final container = _container(
      templates,
      shopping: FakeShoppingListRepository()..saveAllShouldFail = true,
    );

    expect(
      await _controller(container).finish(await _check(container)),
      IngredientCheckFinish.listFailed,
    );
    expect(templates.saved, hasLength(1));
  });

  test('finish is busy until the recipe is saved', () async {
    final gate = Completer<void>();
    final templates = _FakeTemplateRepository(gate: gate);
    final container = _container(templates);
    final check = await _check(container);

    final first = _controller(container).finish(check);
    expect(
      container.read(ingredientCheckControllerProvider('stew')).isSaving,
      isTrue,
    );
    expect(
      await _controller(container).finish(check),
      IngredientCheckFinish.busy,
    );
    gate.complete();

    expect(await first, IngredientCheckFinish.done);
    expect(templates.saved, hasLength(1));
  });

  test('a failed save leaves the picks alone', () async {
    final container = _container(_FakeTemplateRepository(succeeds: false));
    container
        .read(recipeControllerProvider('stew').notifier)
        .pick('500 g Hackfleisch', 'mince');

    expect(
      await _controller(container).finish(await _check(container)),
      IngredientCheckFinish.recipeFailed,
    );

    expect(container.read(recipeControllerProvider('stew')).picks, {
      '500 g Hackfleisch': 'mince',
    });
    expect(
      container.read(ingredientCheckControllerProvider('stew')).isSaving,
      isFalse,
    );
  });
}
