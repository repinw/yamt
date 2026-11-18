import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';

import '../../../../helpers/fake_inventory_item_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 10);

const Map<String, Object?> _answer = {
  'name': 'Tomato Pasta',
  'portions': 2,
  'kcal': 500,
  'protein': 20,
  'carbs': 60,
  'fat': 12,
  'ingredients': [
    {
      'text': '200 g pasta',
      'amount': 200,
      'unit': 'g',
      'kcal': 700,
      'protein': 24,
      'carbs': 140,
      'fat': 4,
    },
  ],
  'instructions': ['Cook pasta.'],
  'image_prompt': 'tomato pasta',
};

class _ThrowingInventory extends FakeInventoryItemRepository {
  new() : super(const []);

  @override
  Future<List<InventoryItem>> readAll() async => throw StateError('offline');
}

class _Harness {
  new({
    List<InventoryItem> stock = const [],
    FakeInventoryItemRepository? inventory,
    Future<String?> Function()? answer,
    Map<String, int> planned = const {},
    Map<String, int> runReserved = const {},
    bool plansFail = false,
  }) {
    container = ProviderContainer(
      overrides: [
        openPlanDemandProvider.overrideWith((ref) async {
          if (plansFail) {
            throw StateError('plans offline');
          }
          return (
            plannedByItemId: planned,
            runReservedByItemId: runReserved,
            missingByItemId: const <String, int>{},
            plannedPortionsByMealId: const <String, double>{},
            missingShareByPlanId: const <String, double>{},
            missingIngredientsByPlanId: const <String, Map<String, int>>{},
            unstockedIngredientsByPlanId:
                const <String, List<PlanUnstockedIngredient>>{},
          );
        }),
        clockProvider.overrideWithValue(() => _now),
        inventoryItemRepositoryProvider.overrideWithValue(
          inventory ?? FakeInventoryItemRepository(stock),
        ),
        aiChefRepositoryProvider.overrideWithValue(
          FirebaseAiChefRepository(
            templateModelClient: ({required templateId, required inputs}) {
              asked = inputs;
              return answer != null
                  ? answer()
                  : Future.value(jsonEncode(_answer));
            },
          ),
        ),
      ],
    );
  }

  late final ProviderContainer container;
  Map<String, Object?>? asked;

  AiChefController get controller =>
      container.read(aiChefControllerProvider.notifier);
}

InventoryItem _item(String name) => InventoryItem.create(
  id: name,
  name: name,
  entryDate: DateTime.utc(2026, 4, 2),
  storeName: 'Store',
  quantity: 1,
);

void main() {
  test('the controller starts without an idea', () {
    final h = _Harness();
    addTearDown(h.container.dispose);

    expect(h.container.read(aiChefControllerProvider).value, isNull);
  });

  test('generateRecipe goes loading, then holds the idea made now', () async {
    final h = _Harness();
    addTearDown(h.container.dispose);
    final states = <AsyncValue<AiChefRecipeIdea?>>[];
    h.container.listen(aiChefControllerProvider, (_, next) => states.add(next));

    await h.controller.generateRecipe(isGerman: false, includeInventory: false);

    expect(states.first, isA<AsyncLoading<AiChefRecipeIdea?>>());
    final idea = states.last.value!;
    expect(idea.recipe.name, 'Tomato Pasta');
    expect(idea.recipe.createdAt, _now);
    expect(idea.imagePrompt, 'tomato pasta');
  });

  test('generateRecipe sends the language, wishes and the Vorrat', () async {
    final h = _Harness(stock: [_item('Tomato')]);
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(
      isGerman: false,
      includeInventory: true,
      wishes: ' quick dinner ',
    );

    expect(h.asked!['language'], 'en');
    expect(h.asked!['seed'], contains('Wishes: quick dinner'));
    expect(h.asked!['inventory'], 'Tomato (available: 1 x)');
  });

  test(
    'generateRecipe sends Bloß nicht and the picks still in the Vorrat',
    () async {
      final h = _Harness(stock: [_item('Spinat'), _item('Quark')]);
      addTearDown(h.container.dispose);

      await h.controller.generateRecipe(
        isGerman: true,
        includeInventory: true,
        excludedIngredients: const ['Koriander'],
        mustUseIds: const {'Quark', 'eaten'},
      );

      expect(h.asked!['excluded_ingredients'], 'Koriander');
      expect(h.asked!['must_use_ingredients'], 'Quark (available: 1 x)');
    },
  );

  test(
    'generateRecipe leaves out what plans and cook runs keep of the Vorrat',
    () async {
      final h = _Harness(
        stock: [
          _item('Kokosnussmilch'),
          _item('Quark'),
          InventoryItem.create(
            id: 'Reis',
            name: 'Reis',
            entryDate: DateTime.utc(2026, 4, 2),
            storeName: 'Store',
            quantity: 3,
          ),
        ],
        planned: const {'Kokosnussmilch': 1, 'Reis': 1},
        runReserved: const {'Reis': 1},
      );
      addTearDown(h.container.dispose);

      await h.controller.generateRecipe(
        isGerman: true,
        includeInventory: true,
        mustUseIds: const {'Kokosnussmilch'},
      );

      expect(
        h.asked!['inventory'],
        'Quark (available: 1 x)\nReis (available: 1 x)',
      );
      expect(h.asked!.containsKey('must_use_ingredients'), isFalse);
      expect(
        (await h.controller.loadPickableItems()).map((item) => item.id),
        isNot(contains('Kokosnussmilch')),
      );
    },
  );

  test('a kept pack never goes out as free when the plans fail', () async {
    final h = _Harness(stock: [_item('Kokosnussmilch')], plansFail: true);
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: true);

    expect(h.asked!['inventory'], '');
    await expectLater(h.controller.loadPickableItems(), throwsStateError);
  });

  test('generateRecipe sends no picks with the Vorrat off', () async {
    final h = _Harness(stock: [_item('Quark')]);
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(
      isGerman: true,
      includeInventory: false,
      mustUseIds: const {'Quark'},
    );

    expect(h.asked!.containsKey('must_use_ingredients'), isFalse);
  });

  test('generateRecipe asks in German with German wishes', () async {
    final h = _Harness();
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(
      isGerman: true,
      includeInventory: false,
      wishes: 'ohne Fleisch',
    );

    expect(h.asked!['language'], 'de');
    expect(h.asked!['seed'], contains('Wünsche: ohne Fleisch'));
  });

  test('generateRecipe leaves the Vorrat out when the option is off', () async {
    final h = _Harness(stock: [_item('Tomato')]);
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: false);

    expect(h.asked!['inventory'], '');
  });

  test('generateRecipe goes on without a Vorrat that cannot be read', () async {
    final h = _Harness(inventory: _ThrowingInventory());
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: true);

    expect(h.asked!['inventory'], '');
    expect(h.container.read(aiChefControllerProvider).value, isNotNull);
  });

  test('generateRecipe stores the error when the answer is unusable', () async {
    final h = _Harness(answer: () async => '{"name": "x"}');
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: false);

    final state = h.container.read(aiChefControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<FormatException>());
  });

  test('generateRecipe stores the error when the request fails', () async {
    final h = _Harness(answer: () async => throw Exception('offline'));
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: false);

    expect(h.container.read(aiChefControllerProvider).hasError, isTrue);
  });

  test('a second try after a failure ends in the idea', () async {
    var calls = 0;
    final h = _Harness(
      answer: () async =>
          ++calls == 1 ? throw Exception('offline') : jsonEncode(_answer),
    );
    addTearDown(h.container.dispose);

    await h.controller.generateRecipe(isGerman: true, includeInventory: false);
    expect(h.container.read(aiChefControllerProvider).hasError, isTrue);
    await h.controller.generateRecipe(isGerman: true, includeInventory: false);

    expect(h.container.read(aiChefControllerProvider).value, isNotNull);
  });

  test(
    'an idea that arrives after the controller is gone is dropped',
    () async {
      final answer = Completer<String?>();
      final h = _Harness(answer: () => answer.future);
      final subscription = h.container.listen(
        aiChefControllerProvider,
        (_, _) {},
      );
      final done = h.controller.generateRecipe(
        isGerman: true,
        includeInventory: false,
      );
      await pumpEventQueue();

      subscription.close();
      h.container.dispose();
      answer.complete(jsonEncode(_answer));

      await done;
    },
  );

  test(
    'generateRecipe fails when picks meet a Vorrat that cannot be read',
    () async {
      final h = _Harness(inventory: _ThrowingInventory());
      addTearDown(h.container.dispose);

      await h.controller.generateRecipe(
        isGerman: true,
        includeInventory: true,
        mustUseIds: const {'Quark'},
      );

      expect(h.asked, isNull);
      expect(h.container.read(aiChefControllerProvider).hasError, isTrue);
    },
  );

  test(
    'loadPickableItems gives the Vorrat the longest in stock first',
    () async {
      final h = _Harness(
        stock: [
          InventoryItem.create(
            id: 'new',
            name: 'Quark',
            entryDate: DateTime.utc(2026, 11, 10),
            storeName: 'Store',
            quantity: 1,
          ),
          _item('Tomato'),
        ],
      );
      addTearDown(h.container.dispose);

      final items = await h.controller.loadPickableItems();

      expect(items.map((item) => item.id), ['Tomato', 'new']);
    },
  );
}
