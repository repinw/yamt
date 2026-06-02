import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/ai_chef/data/'
    'ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';

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

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this.items);

  final List<InventoryItem> items;

  @override
  FutureOr<List<InventoryItem>> build() {
    return items;
  }
}

class _PendingInventoryItemsController extends InventoryItemsController {
  _PendingInventoryItemsController(this.itemsCompleter);

  final Completer<List<InventoryItem>> itemsCompleter;

  @override
  FutureOr<List<InventoryItem>> build() {
    return itemsCompleter.future;
  }
}

@Dependencies([AiChefController])
void main() {
  test('generateRecipe passes active inventory ingredients to repo', () async {
    final repository = _RecordingAiChefRepository(
      recipe: _recipe(name: 'Tomato Pasta'),
    );
    final inventoryController = _StaticInventoryItemsController([
      _inventoryItem(
        id: 'tomato',
        name: 'Tomato',
        quantity: 2,
        weight: '500 g',
        brand: 'Garden',
      ),
      _inventoryItem(
        id: 'milk',
        name: 'Milk',
        quantity: 1,
        initialAmount: 1000,
        currentAmount: 750,
        amountUnit: InventoryAmountUnit.milliliter,
      ),
      _inventoryItem(id: 'empty-rice', name: 'Rice', quantity: 0),
    ]);
    final container = ProviderContainer(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(repository),
        inventoryItemsControllerProvider.overrideWith(
          () => inventoryController,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(aiChefControllerProvider.notifier)
        .generateRecipe(
          isGerman: false,
          includeInventory: true,
          wishes: 'quick dinner',
        );

    final state = container.read(aiChefControllerProvider);
    expect(state.value?.name, 'Tomato Pasta');
    expect(repository.languageCode, 'en');
    expect(repository.seed, contains('Wishes: quick dinner'));
    expect(repository.inventoryIngredients, <String>[
      'Tomato (available: 2 x 500 g, brand: Garden)',
      'Milk (available: 750 ml)',
    ]);
  });

  test(
    'generateRecipe waits for loading inventory before calling repo',
    () async {
      final repository = _RecordingAiChefRepository(
        recipe: _recipe(name: 'Pantry Soup'),
      );
      final itemsCompleter = Completer<List<InventoryItem>>();
      final container = ProviderContainer(
        overrides: [
          aiChefRepositoryProvider.overrideWithValue(repository),
          inventoryItemsControllerProvider.overrideWith(
            () => _PendingInventoryItemsController(itemsCompleter),
          ),
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
          .generateRecipe(isGerman: false, includeInventory: true);
      await pumpEventQueue();

      expect(repository.inventoryIngredients, isNull);

      itemsCompleter.complete([
        _inventoryItem(id: 'carrot', name: 'Carrot', quantity: 3),
      ]);
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
        inventoryItemsControllerProvider.overrideWith(
          () => _StaticInventoryItemsController([
            _inventoryItem(id: 'tomato', name: 'Tomato', quantity: 2),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(aiChefControllerProvider.notifier)
        .generateRecipe(
          isGerman: true,
          includeInventory: false,
          wishes: 'ohne Fleisch',
        );

    expect(repository.languageCode, 'de');
    expect(repository.seed, contains('Wünsche: ohne Fleisch'));
    expect(repository.inventoryIngredients, isEmpty);
  });

  test('generateRecipe stores error when repository returns null', () async {
    final repository = _RecordingAiChefRepository();
    final container = ProviderContainer(
      overrides: [
        aiChefRepositoryProvider.overrideWithValue(repository),
        inventoryItemsControllerProvider.overrideWith(
          () => _StaticInventoryItemsController(const <InventoryItem>[]),
        ),
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

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int quantity,
  String? weight,
  String? brand,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: 2,
    weight: weight,
    brand: brand,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
  );
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
