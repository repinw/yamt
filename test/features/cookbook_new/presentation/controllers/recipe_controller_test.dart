import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_view.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

InventoryItem _item(String id, String name, {int amount = 2000}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10, 9),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 2000,
      currentAmount: amount,
      amountUnit: InventoryAmountUnit.gram,
    );

PreparedMeal _recipe({
  Map<String, List<String>> assignments = const <String, List<String>>{},
}) {
  final now = DateTime.utc(2026, 10, 9);
  return PreparedMeal(
    id: 'stew',
    name: 'Bauerntopf',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
    recipeIngredients: const ['500 g Hackfleisch', '200 g Karotten', 'Salz'],
    ignoredRecipeIngredients: const ['Salz'],
    recipeIngredientAssignments: assignments,
  );
}

class _FakeCookingService implements PreparedMealCookingService {
  new({this.succeeds = true, this.throws = false, this.gate});

  final bool succeeds;
  final bool throws;
  final Completer<void>? gate;
  final calls =
      <
        ({
          PreparedMeal recipe,
          int portions,
          Map<String, List<String>> assignments,
        })
      >[];

  @override
  Future<PreparedMealCreationResult> cookRecipe({
    required PreparedMeal recipe,
    required int portions,
    required Map<String, List<String>> assignments,
  }) async {
    calls.add((recipe: recipe, portions: portions, assignments: assignments));
    await gate?.future;
    if (throws) {
      throw StateError('offline');
    }
    return succeeds
        ? const PreparedMealCreationResult.success('meal')
        : const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.mealSaveFailed,
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container({
  PreparedMeal? recipe,
  _FakeCookingService? service,
  List<InventoryItem>? items,
}) {
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value([?recipe])),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(
          items ??
              [
                _item('mince', 'Hackfleisch'),
                _item('carrots', 'Karotten'),
                _item('organic-carrots', 'Bio Karotten'),
              ],
        ),
      ),
      preparedMealCookingServiceProvider.overrideWithValue(
        service ?? _FakeCookingService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(recipeControllerProvider('stew'), (_, _) {});
  return container;
}

Future<RecipeView?> _view(ProviderContainer container) async {
  final provider = recipeViewProvider('stew', 'de');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  while (container.read(provider).isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider).requireValue;
}

RecipeController _controller(ProviderContainer container) =>
    container.read(recipeControllerProvider('stew').notifier);

void main() {
  test('cooks with the Kochhelfer until the cook turns it off', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = recipeControllerProvider('stew');
    container.listen(provider, (_, _) {});

    expect(container.read(provider).withGuide, isTrue);
    container.read(provider.notifier).setWithGuide(withGuide: false);
    expect(container.read(provider).withGuide, isFalse);
  });

  test(
    'sizes the ingredients for the portions and matches the Vorrat',
    () async {
      final container = _container(recipe: _recipe());

      var view = (await _view(container))!;
      expect(view.portions, 2);
      expect(view.lines.first.row.requirement?.amount, 500);
      expect(view.lines.first.row.stockItem?.id, 'mince');

      _controller(container).setPortions(4);
      view = (await _view(container))!;
      expect(view.portions, 4);
      expect(view.lines.first.row.requirement?.amount, 1000);
    },
  );

  test(
    'takes the Vorrat item the recipe saved before the best match',
    () async {
      final container = _container(
        recipe: _recipe(
          assignments: const {
            '200 g Karotten': ['organic-carrots'],
          },
        ),
      );

      final view = (await _view(container))!;

      expect(view.lines[1].row.stockItem?.id, 'organic-carrots');
    },
  );

  test(
    'skips a used-up saved item for the next one the recipe saved',
    () async {
      final container = _container(
        recipe: _recipe(
          assignments: const {
            '200 g Karotten': ['used-carrots', 'organic-carrots'],
          },
        ),
        items: [
          _item('carrots', 'Karotten'),
          _item('used-carrots', 'Karotten', amount: 0),
          _item('organic-carrots', 'Bio Karotten'),
        ],
      );

      final view = (await _view(container))!;

      expect(view.lines[1].row.stockItem?.id, 'organic-carrots');
    },
  );

  test('a saved amount conversion lets pieces come from grams', () async {
    final recipe = _recipe().copyWith(
      recipeIngredients: const ['2 Eier'],
      ignoredRecipeIngredients: const <String>[],
      recipeIngredientAmountConversions: const {
        '2 Eier': RecipeIngredientAmountConversion(
          amountPerPiece: 60,
          unit: InventoryAmountUnit.gram,
        ),
      },
    );
    final container = _container(
      recipe: recipe,
      items: [_item('eggs', 'Eier')],
    );

    final view = (await _view(container))!;

    expect(view.lines.single.row.stockItem?.id, 'eggs');
    expect(view.lines.single.candidates.map((item) => item.id), ['eggs']);
  });

  test('a pick replaces the match, and none leaves the Vorrat alone', () async {
    final container = _container(recipe: _recipe());

    _controller(container)
      ..pick('200 g Karotten', 'organic-carrots')
      ..pick('500 g Hackfleisch', null);
    final view = (await _view(container))!;

    expect(view.lines.first.row.stockItem, isNull);
    expect(view.lines[1].row.stockItem?.id, 'organic-carrots');
    expect(view.assignments, {
      '200 g Karotten': ['organic-carrots'],
    });
  });

  test('ignored ingredients do not count', () async {
    final container = _container(recipe: _recipe());

    final view = (await _view(container))!;

    expect(view.lines.last.isIgnored, isTrue);
    expect(view.activeLines.map((line) => line.ingredient), [
      '500 g Hackfleisch',
      '200 g Karotten',
    ]);
    expect(view.assignments.keys, ['500 g Hackfleisch', '200 g Karotten']);
  });

  test('cook puts the recipe for the chosen portions in the pot', () async {
    final service = _FakeCookingService();
    final container = _container(recipe: _recipe(), service: service);
    _controller(container).setPortions(3);
    final view = (await _view(container))!;

    final mealId = await _controller(container).cook(view);

    expect(mealId, 'meal');
    final call = service.calls.single;
    expect(call.recipe.id, 'stew');
    expect(call.portions, 3);
    expect(call.assignments, {
      '500 g Hackfleisch': ['mince'],
      '200 g Karotten': ['carrots'],
    });
    expect(container.read(recipeControllerProvider('stew')).isCooking, isFalse);
  });

  test('cook is busy until the meal is saved', () async {
    final gate = Completer<void>();
    final service = _FakeCookingService(gate: gate);
    final container = _container(recipe: _recipe(), service: service);
    final view = (await _view(container))!;

    final cooking = _controller(container).cook(view);
    expect(container.read(recipeControllerProvider('stew')).isCooking, isTrue);
    expect(await _controller(container).cook(view), isNull);
    gate.complete();

    expect(await cooking, 'meal');
    expect(service.calls, hasLength(1));
  });

  test('cook reports a failed save', () async {
    final container = _container(
      recipe: _recipe(),
      service: _FakeCookingService(succeeds: false),
    );
    final view = (await _view(container))!;

    expect(await _controller(container).cook(view), isNull);
  });

  test('cook reports a thrown error as a failed save', () async {
    final container = _container(
      recipe: _recipe(),
      service: _FakeCookingService(throws: true),
    );
    final view = (await _view(container))!;

    expect(await _controller(container).cook(view), isNull);
    expect(container.read(recipeControllerProvider('stew')).isCooking, isFalse);
  });

  test('a recipe that is gone has no view', () async {
    final container = _container();

    expect(await _view(container), isNull);
  });
}
