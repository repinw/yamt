import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/'
    'ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

class _RecordingAiChefRepository extends FirebaseAiChefRepository {
  _RecordingAiChefRepository({this.recipe});

  PreparedMeal? recipe;
  String? languageCode;
  String? seed;
  List<String>? inventoryIngredients;

  @override
  Future<PreparedMeal?> generateAiRecipe({
    required String languageCode,
    required String seed,
    List<String> inventoryIngredients = const [],
  }) async {
    this.languageCode = languageCode;
    this.seed = seed;
    this.inventoryIngredients = List<String>.from(inventoryIngredients);
    return recipe;
  }
}

void main() {
  test(
    'generateRecipe passes supplied inventory ingredients to repo',
    () async {
      final repository = _RecordingAiChefRepository(
        recipe: _recipe(name: 'Tomato Pasta'),
      );
      final inventoryIngredients = <String>[
        'Tomato (available: 2 x 500 g, brand: Garden)',
        'Milk (available: 750 ml)',
      ];
      final container = ProviderContainer(
        overrides: [
          aiChefRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiChefControllerProvider.notifier)
          .generateRecipe(
            isGerman: false,
            includeInventory: true,
            wishes: 'quick dinner',
            inventoryIngredientsLoader: () async => inventoryIngredients,
          );

      final state = container.read(aiChefControllerProvider);
      expect(state.value?.name, 'Tomato Pasta');
      expect(repository.languageCode, 'en');
      expect(repository.seed, contains('Wishes: quick dinner'));
      expect(repository.inventoryIngredients, inventoryIngredients);
    },
  );

  test(
    'generateRecipe waits for loading inventory before calling repo',
    () async {
      final repository = _RecordingAiChefRepository(
        recipe: _recipe(name: 'Pantry Soup'),
      );
      final ingredientsCompleter = Completer<List<String>>();
      final container = ProviderContainer(
        overrides: [
          aiChefRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        aiChefControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final generateFuture = container
          .read(aiChefControllerProvider.notifier)
          .generateRecipe(
            isGerman: false,
            includeInventory: true,
            inventoryIngredientsLoader: () => ingredientsCompleter.future,
          );
      await pumpEventQueue();

      expect(repository.inventoryIngredients, isNull);

      ingredientsCompleter.complete(['Carrot (available: 3 x)']);
      await generateFuture;

      expect(repository.inventoryIngredients, <String>[
        'Carrot (available: 3 x)',
      ]);
    },
  );

  test('generateRecipe skips inventory when option is disabled', () async {
    final repository = _RecordingAiChefRepository(
      recipe: _recipe(name: 'Soup'),
    );
    final container = ProviderContainer(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    var didLoadInventory = false;

    await container
        .read(aiChefControllerProvider.notifier)
        .generateRecipe(
          isGerman: true,
          includeInventory: false,
          wishes: 'ohne Fleisch',
          inventoryIngredientsLoader: () async {
            didLoadInventory = true;
            return const <String>['Tomato'];
          },
        );

    expect(repository.languageCode, 'de');
    expect(repository.seed, contains('Wünsche: ohne Fleisch'));
    expect(repository.inventoryIngredients, isEmpty);
    expect(didLoadInventory, isFalse);
  });

  test('generateRecipe stores error when repository returns null', () async {
    final repository = _RecordingAiChefRepository();
    final container = ProviderContainer(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(aiChefControllerProvider.notifier)
        .generateRecipe(isGerman: true, includeInventory: true);

    final state = container.read(aiChefControllerProvider);
    expect(state.hasError, isTrue);
    expect(repository.languageCode, 'de');
  });
}

PreparedMeal _recipe({required String name}) {
  return PreparedMeal(
    id: 'recipe-1',
    name: name,
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 60,
    totalFat: 12,
    createdAt: DateTime.parse('2026-04-02T12:00:00Z'),
    updatedAt: DateTime.parse('2026-04-02T12:00:00Z'),
    components: const <PreparedMealComponent>[],
    recipeIngredients: const <String>['200 g pasta'],
    recipeInstructions: const <String>['Cook pasta.'],
  );
}
