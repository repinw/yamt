import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
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
import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../../helpers/fake_cook_run_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../../helpers/fake_recipe_estimate_client.dart';
import '../../../recipes/cook_run_fixtures.dart';

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

/// A Vorlage of mince and carrots, cooked for two portions.
PreparedMeal _carrotVorlage() => _recipe().copyWith(
  totalPortions: 2,
  recipeIngredients: const <String>[],
  ignoredRecipeIngredients: const <String>[],
  components: [
    _component('mince', 'Hackfleisch', 500),
    _component('carrots', 'Karotten', 200),
  ],
);

PreparedMealComponent _component(
  String itemId,
  String name,
  int amount, {
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
  InventoryItem? snapshot,
}) => PreparedMealComponent(
  inventoryItemId: itemId,
  name: name,
  brand: null,
  imageUrl: null,
  usedAmount: amount,
  usedUnit: unit,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  sourceItemSnapshot: snapshot ?? _item(itemId, name),
);

class _FakeCookingService implements PreparedMealCookingService {
  new({this.succeeds = true, this.throws = false, this.gate});

  final bool succeeds;
  final bool throws;
  final Completer<void>? gate;
  final vorlageCalls = <({int portions, List<VorlageFood> foods})>[];

  @override
  Future<PreparedMealCreationResult> cookVorlage({
    required PreparedMeal vorlage,
    required int portions,
    required List<VorlageFood> foods,
  }) async {
    vorlageCalls.add((portions: portions, foods: foods));
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

/// Keeps the plans saved and deleted through it.
class _FakeDayLog implements CalorieDayLogService {
  final saved = <CalorieEntry>[];
  final deleted = <CalorieEntry>[];

  @override
  Future<void> plan(CalorieEntry plan) async => saved.add(plan);

  @override
  Future<void> deletePlans(List<CalorieEntry> plans) async =>
      deleted.addAll(plans);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container({
  PreparedMeal? recipe,
  _FakeCookingService? service,
  List<InventoryItem>? items,
  _FakeDayLog? dayLog,
  List<CookRun> runs = const <CookRun>[],
}) {
  final container = ProviderContainer(
    overrides: [
      cookRunRepositoryProvider.overrideWithValue(
        FakeCookRunRepository(runs: runs),
      ),
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
      calorieDayLogServiceProvider.overrideWithValue(dayLog ?? _FakeDayLog()),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 9, 12)),
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
  test(
    'sizes the ingredients for the portions and matches the Vorrat',
    () async {
      final container = _container(recipe: _recipe());

      var view = (await _view(container))!;
      expect(view.portions, 2);
      expect(view.lines.first.row.requirement?.amount, 500);
      expect(view.lines.first.items.first.id, 'mince');

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

      expect(view.lines[1].items.first.id, 'organic-carrots');
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

      expect(view.lines[1].items.first.id, 'organic-carrots');
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

    expect(view.lines.single.items.first.id, 'eggs');
  });

  test('a recipe with a cook run is sized for the run portions', () async {
    final container = _container(
      recipe: _recipe(),
      runs: [buildCookRun(id: 'recipe-stew', recipeId: 'stew', portions: 6)],
    );

    final view = (await _view(container))!;

    expect(view.portions, 6);
    expect(view.lines.first.row.requirement?.amount, 1500);
  });

  test('a cook run of another recipe does not size the recipe', () async {
    final container = _container(
      recipe: _recipe(),
      runs: [buildCookRun(id: 'recipe-x', recipeId: 'other', portions: 6)],
    );

    final view = (await _view(container))!;

    expect(view.portions, 2);
    expect(view.lines.first.row.requirement?.amount, 500);
  });

  test('a Vorlage ignores a cook run', () async {
    final container = _container(
      recipe: _carrotVorlage(),
      runs: [buildCookRun(id: 'recipe-stew', recipeId: 'stew', portions: 6)],
    );

    final view = (await _view(container))!;

    expect(view.portions, 2);
    expect(view.lines.first.row.requirement?.amount, 500);
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

  test('cook puts the Vorlage for the chosen portions in the pot', () async {
    final service = _FakeCookingService();
    final container = _container(recipe: _carrotVorlage(), service: service);
    _controller(container).setPortions(3);
    final view = (await _view(container))!;

    final mealId = await _controller(container).cook(view);

    expect(mealId, 'meal');
    final call = service.vorlageCalls.single;
    expect(call.portions, 3);
    expect(
      call.foods.map(
        (food) => (food.name, food.amount, food.itemIds.join(' ')),
      ),
      <(String, double, String)>[
        ('Hackfleisch', 750, 'mince'),
        ('Karotten', 300, 'carrots'),
      ],
    );
    expect(container.read(recipeControllerProvider('stew')).isCooking, isFalse);
  });

  test('cook is busy until the meal is saved', () async {
    final gate = Completer<void>();
    final service = _FakeCookingService(gate: gate);
    final container = _container(recipe: _carrotVorlage(), service: service);
    final view = (await _view(container))!;

    final cooking = _controller(container).cook(view);
    expect(container.read(recipeControllerProvider('stew')).isCooking, isTrue);
    expect(await _controller(container).cook(view), isNull);
    gate.complete();

    expect(await cooking, 'meal');
    expect(service.vorlageCalls, hasLength(1));
  });

  test('cook reports a failed save', () async {
    final container = _container(
      recipe: _carrotVorlage(),
      service: _FakeCookingService(succeeds: false),
    );
    final view = (await _view(container))!;

    expect(await _controller(container).cook(view), isNull);
  });

  test('cook reports a thrown error as a failed save', () async {
    final container = _container(
      recipe: _carrotVorlage(),
      service: _FakeCookingService(throws: true),
    );
    final view = (await _view(container))!;

    expect(await _controller(container).cook(view), isNull);
    expect(container.read(recipeControllerProvider('stew')).isCooking, isFalse);
  });

  test('plan saves one portion of the recipe as the page cooks it', () async {
    final dayLog = _FakeDayLog();
    final container = _container(recipe: _recipe(), dayLog: dayLog);
    _controller(container).setPortions(4);
    final view = (await _view(container))!;

    final plan = await _controller(container)
        .plan(view, DateTime(2026, 10, 11));

    expect(dayLog.saved, [plan]);
    expect(plan!.bundleSourceTemplateId, 'stew');
    expect(plan.bundleSourcePreparedMealId, isNull);
    expect(plan.bundleConsumedPortions, 1);
    expect(plan.bundleTotalPortions, 4);
    expect(plan.nutritionPending, isFalse);
    expect(plan.bundleComponents.map((component) => component.name), [
      'Hackfleisch',
      'Karotten',
    ]);
    expect(plan.loggedAt, DateTime(2026, 10, 11, 12));
  });

  test('plan counts an item with too little stock in full', () async {
    final container = _container(
      recipe: _recipe(),
      items: [
        _item('mince', 'Hackfleisch', amount: 100),
        _item('carrots', 'Karotten'),
      ],
    );
    final view = (await _view(container))!;

    final plan = await _controller(container)
        .plan(view, DateTime(2026, 10, 11));

    expect(plan!.nutritionPending, isFalse);
    expect(plan.bundleComponents.first.amountLabel, '250 g');
  });

  test('plan with an ingredient not from the Vorrat is a reminder', () async {
    final container = _container(
      recipe: _recipe(),
      items: [_item('carrots', 'Karotten')],
    );
    final view = (await _view(container))!;

    final plan = await _controller(container)
        .plan(view, DateTime(2026, 10, 11));

    expect(plan!.nutritionPending, isTrue);
    expect(plan.totalKcal, 0);
  });

  test('plan of a Vorlage takes a portion of its own values', () async {
    final vorlage = _recipe().copyWith(
      recipeIngredients: const <String>[],
      ignoredRecipeIngredients: const <String>[],
      totalKcal: 800,
    );
    final container = _container(recipe: vorlage);
    final view = (await _view(container))!;

    final plan = await _controller(container)
        .plan(view, DateTime(2026, 10, 11));

    expect(plan!.totalKcal, 400);
    expect(plan.bundleSourceTemplateId, 'stew');
  });

  test(
    'a Vorlage shows one line per food from its items and cooks them',
    () async {
      final lemon = _item(
        'lemon',
        'Zitrone',
      ).copyWith(amountUnit: InventoryAmountUnit.piece, amountScale: 1000);
      final vorlage = _recipe().copyWith(
        totalPortions: 1,
        recipeIngredients: const <String>[],
        ignoredRecipeIngredients: const <String>[],
        components: [
          _component('mince', 'Hackfleisch', 200),
          _component('mince-2', 'Hackfleisch', 50),
          _component('carrots', 'Karotten', 100),
          _component('eggs', 'Eier', 2, unit: InventoryAmountUnit.piece),
          // A pack size in the name is no amount.
          _component(
            'mozzarella',
            'Mozzarella 125 g',
            2,
            unit: InventoryAmountUnit.piece,
          ),
          // A third of a lemon still counts as one.
          _component(
            'lemon',
            'Zitrone',
            300,
            unit: InventoryAmountUnit.piece,
            snapshot: lemon,
          ),
        ],
      );
      final service = _FakeCookingService();
      final container = _container(
        recipe: vorlage,
        service: service,
        items: [
          _item('mince', 'Hackfleisch'),
          _item('mince-2', 'Hackfleisch'),
          _item('carrots', 'Karotten'),
          _item('eggs', 'Eier').copyWith(amountUnit: InventoryAmountUnit.piece),
          _item(
            'mozzarella',
            'Mozzarella 125 g',
          ).copyWith(amountUnit: InventoryAmountUnit.piece),
          lemon,
        ],
      );
      _controller(container).setPortions(2);
      final view = (await _view(container))!;

      expect(view.isVorlage, isTrue);
      // Two packs of the same food are one line, written for the Vorlage's
      // own portion, and pieces go without a unit.
      expect(view.lines.map((line) => line.ingredient), [
        '250 g Hackfleisch',
        '100 g Karotten',
        '2 Eier',
        '2 Mozzarella',
        '1 Zitrone',
      ]);
      // The needed amounts are sized for the two portions.
      expect(view.lines.map((line) => line.row.requirement!.amount), [
        500,
        200,
        4,
        4,
        1,
      ]);
      final mozzarella = view.lines[3].row.requirement!;
      expect(mozzarella.amount, 4);
      expect(mozzarella.unit, TemplateIngredientUnit.piece);
      // Part of a lemon still needs one lemon in the Vorrat.
      expect(view.lines.last.row.requirement!.amount, 1);
      expect(view.lines.first.items.map((item) => item.id), [
        'mince',
        'mince-2',
      ]);

      // Cooking takes the foods' own amounts for two portions, a third of
      // a lemon included, without reading the lines again.
      await _controller(container).cook(view);
      final call = service.vorlageCalls.single;
      expect(call.portions, 2);
      expect(
        call.foods.map(
          (food) => (food.name, food.amount, food.itemIds.join(' ')),
        ),
        <(String, double, String)>[
          ('Hackfleisch', 500, 'mince mince-2'),
          ('Karotten', 200, 'carrots'),
          ('Eier', 4, 'eggs'),
          ('Mozzarella', 4, 'mozzarella'),
          ('Zitrone', 0.6, 'lemon'),
        ],
      );
    },
  );

  test('unplan deletes the plan again', () async {
    final dayLog = _FakeDayLog();
    final container = _container(recipe: _recipe(), dayLog: dayLog);
    final view = (await _view(container))!;
    final plan = await _controller(container)
        .plan(view, DateTime(2026, 10, 11));

    expect(await _controller(container).unplan(plan!), isTrue);
    expect(dayLog.deleted, [plan]);
  });

  group('estimateIfMissing', () {
    RecipeEstimate fitting(PreparedMeal recipe) => RecipeEstimate(
      kcal: 450,
      protein: 30,
      carbs: 40,
      fat: 12,
      portions: recipe.totalPortions,
      linesKey: recipeLinesKey(recipe.recipeIngredients),
      createdAt: DateTime.utc(2026, 10, 9),
    );

    // The real service over a fake template store and a fake AI client: the
    // repository layer is what the tests fake.
    ({
      ProviderContainer container,
      FakePreparedMealTemplateRepository templates,
      FakeRecipeEstimateClient client,
    })
    estimating(
      PreparedMeal? recipe, {
      FakeRecipeEstimateClient? client,
      List<Override> overrides = const [],
    }) {
      final templates = FakePreparedMealTemplateRepository(
        templates: [?recipe],
      );
      final fake = client ?? FakeRecipeEstimateClient();
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
          recipeEstimateTemplateClientProvider.overrideWithValue(fake.request),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 9, 12)),
          ...overrides,
        ],
      );
      addTearDown(container.dispose);
      container.listen(recipeControllerProvider('stew'), (_, _) {});
      return (container: container, templates: templates, client: fake);
    }

    Set<String> failed(ProviderContainer container) =>
        container.read(recipeControllerProvider('stew')).failedEstimates;

    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 400 && !condition(); i += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(condition(), isTrue);
    }

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 60));

    test('estimates a recipe without an estimate, and a success is no '
        'failure', () async {
      final recipe = _recipe();
      final setup = estimating(recipe);

      _controller(setup.container).estimateIfMissing(recipe);
      await until(
        () => setup.templates.templates.single.recipeEstimate != null,
      );
      await settle();

      expect(setup.client.calls, 1);
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 420);
      expect(failed(setup.container), isEmpty);
    });

    test(
      'estimates a recipe whose estimate no longer fits its lines',
      () async {
        final recipe = _recipe();
        final stale = recipe.copyWith(
          recipeEstimate: fitting(recipe.copyWith(recipeIngredients: ['Reis'])),
        );
        final setup = estimating(stale);

        _controller(setup.container).estimateIfMissing(stale);
        await until(() => setup.client.calls == 1);
        await settle();

        expect(
          setup.templates.templates.single.fittingRecipeEstimate,
          isNotNull,
        );
      },
    );

    test('leaves a recipe with a fitting estimate', () async {
      final recipe = _recipe();
      final estimated = recipe.copyWith(recipeEstimate: fitting(recipe));
      final setup = estimating(estimated);

      _controller(setup.container).estimateIfMissing(estimated);
      await settle();

      expect(setup.client.calls, 0);
      expect(failed(setup.container), isEmpty);
    });

    test('leaves a Vorlage without ingredient lines', () async {
      final vorlage = _recipe().copyWith(
        recipeIngredients: const <String>[],
        ignoredRecipeIngredients: const <String>[],
      );
      final setup = estimating(vorlage);

      _controller(setup.container).estimateIfMissing(vorlage);
      await settle();

      expect(setup.client.calls, 0);
      expect(failed(setup.container), isEmpty);
    });

    test('a failed estimate adds its key to failedEstimates', () async {
      final recipe = _recipe();
      final setup = estimating(recipe)..client.failure = Exception('offline');

      _controller(setup.container).estimateIfMissing(recipe);
      await until(() => failed(setup.container).isNotEmpty);

      expect(failed(setup.container), {recipe.recipeEstimateKey});
      expect(
        setup.container
            .read(recipeControllerProvider('stew'))
            .waitsForEstimate(recipe),
        isFalse,
      );
    });

    test('an answer that cannot be used adds its key too', () async {
      final recipe = _recipe();
      final setup = estimating(
        recipe,
        client: FakeRecipeEstimateClient(noAnswer: true),
      );

      _controller(setup.container).estimateIfMissing(recipe);
      await until(() => failed(setup.container).isNotEmpty);

      expect(failed(setup.container), {recipe.recipeEstimateKey});
    });

    test('a recipe that is gone adds its key', () async {
      final recipe = _recipe();
      final setup = estimating(null);

      _controller(setup.container).estimateIfMissing(recipe);
      await until(() => failed(setup.container).isNotEmpty);

      expect(failed(setup.container), {recipe.recipeEstimateKey});
      expect(setup.client.calls, 0);
    });

    test('lines that changed meanwhile add the old key', () async {
      final recipe = _recipe();
      final setup = estimating(recipe)..client.hold();

      _controller(setup.container).estimateIfMissing(recipe);
      await until(() => setup.client.calls == 1);
      await setup.templates.save(
        recipe.copyWith(recipeIngredients: ['500 g Hackfleisch']),
      );
      setup.client.release();
      await until(() => failed(setup.container).isNotEmpty);

      expect(failed(setup.container), {recipe.recipeEstimateKey});
    });

    test('the same key is estimated once, a new key again', () async {
      final recipe = _recipe();
      final setup = estimating(recipe);
      final controller = _controller(setup.container)
        ..estimateIfMissing(recipe)
        ..estimateIfMissing(recipe);
      await until(() => setup.client.calls == 1);
      controller.estimateIfMissing(recipe);
      await settle();

      expect(setup.client.calls, 1);

      final changed = recipe.copyWith(
        recipeIngredients: ['500 g Hackfleisch', '300 g Karotten'],
      );
      await setup.templates.save(changed);
      controller.estimateIfMissing(changed);
      await until(() => setup.client.calls == 2);
      await settle();

      expect(setup.client.calls, 2);
      expect(failed(setup.container), isEmpty);
    });

    test('a service that throws at once while the page builds does not '
        'assert', () async {
      final recipe = _recipe();
      final builds = Provider<int>((ref) {
        // Like the page does while it builds.
        ref
            .watch(recipeControllerProvider('stew').notifier)
            .estimateIfMissing(recipe);
        return 1;
      });
      final setup = estimating(
        recipe,
        overrides: [
          recipeEstimateServiceProvider.overrideWith(
            (ref) => throw StateError('no service'),
          ),
        ],
      );

      expect(setup.container.read(builds), 1);
      await until(() => failed(setup.container).isNotEmpty);

      expect(failed(setup.container), {recipe.recipeEstimateKey});
    });
  });

  test('a recipe that is gone has no view', () async {
    final container = _container();

    expect(await _view(container), isNull);
  });
}
