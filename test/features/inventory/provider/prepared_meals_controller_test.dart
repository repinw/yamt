import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
  List<InventoryItem> savedItems = const <InventoryItem>[];
  final List<List<InventoryItem>> saveHistory = <List<InventoryItem>>[];

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    savedItems = List<InventoryItem>.from(items);
    saveHistory.add(List<InventoryItem>.from(items));
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(_items)..addAll(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  _FakePreparedMealRepository({
    required List<PreparedMeal> initialMeals,
    this.throwOnSave = false,
    this.saveDelay = Duration.zero,
  }) : _meals = List<PreparedMeal>.from(initialMeals);

  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _meals;
  List<PreparedMeal> savedMeals = const <PreparedMeal>[];
  bool throwOnSave;
  final Duration saveDelay;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_meals));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_meals);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }
    if (throwOnSave) {
      throw Exception('prepared-meal-save-failed');
    }
    _meals = List<PreparedMeal>.from(meals);
    savedMeals = List<PreparedMeal>.from(meals);
    _controller.add(List<PreparedMeal>.from(_meals));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(preparedMealsControllerProvider, (previous, next) {});
}

InventoryItem _item({
  required String id,
  required String name,
  required int currentAmount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 300,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );
}

PreparedMeal _meal({
  required String id,
  required String name,
  required InventoryItem item,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    imageBase64: base64Encode(<int>[1, 2, 3]),
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: item.id,
        name: item.name,
        brand: item.brand,
        imageUrl: item.imageUrl,
        usedAmount: 200,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 400,
        totalProtein: 20,
        totalCarbs: 40,
        totalFat: 10,
        sourceItemSnapshot: item,
      ),
    ],
  );
}

void main() {
  test(
    'createPreparedMeal reduces inventory and saves a prepared meal',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(id: 'rice', name: 'Rice', currentAmount: 300),
          _item(id: 'beans', name: 'Beans', currentAmount: 250),
        ],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final result = await container
          .read(preparedMealsControllerProvider.notifier)
          .createPreparedMeal(
            name: 'Rice & Beans',
            imageBase64: base64Encode(<int>[1, 2, 3]),
            totalPortions: 2,
            items: const [
              PreparedMealItemInput(itemId: 'rice', usedAmount: 200),
              PreparedMealItemInput(itemId: 'beans', usedAmount: 100),
            ],
          );

      expect(result.isSuccess, isTrue);
      expect(inventoryRepository.savedItems[0].currentAmount, 100);
      expect(inventoryRepository.savedItems[1].currentAmount, 150);
      expect(preparedMealRepository.savedMeals, hasLength(1));
      expect(preparedMealRepository.savedMeals.single.totalPortions, 2);
      expect(preparedMealRepository.savedMeals.single.imageBase64, isNotNull);
      expect(preparedMealRepository.savedMeals.single.components, hasLength(2));
    },
  );

  test(
    'createPreparedMeal restores inventory when prepared meal save throws',
    () async {
      final originalItems = [
        _item(id: 'rice', name: 'Rice', currentAmount: 300),
        _item(id: 'beans', name: 'Beans', currentAmount: 250),
      ];
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: originalItems,
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
        throwOnSave: true,
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final result = await container
          .read(preparedMealsControllerProvider.notifier)
          .createPreparedMeal(
            name: 'Rice & Beans',
            totalPortions: 2,
            items: const [
              PreparedMealItemInput(itemId: 'rice', usedAmount: 200),
              PreparedMealItemInput(itemId: 'beans', usedAmount: 100),
            ],
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        PreparedMealCreationFailureReason.mealSaveFailed,
      );
      expect(inventoryRepository.saveHistory, hasLength(2));
      expect(inventoryRepository.savedItems[0].currentAmount, 300);
      expect(inventoryRepository.savedItems[1].currentAmount, 250);
      expect(
        container.read(preparedMealsControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test(
    'consumePreparedMeal creates bundle entry and reduces portions',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [_meal(id: 'meal-1', name: 'Lunch box', item: item)],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 2,
            mealType: MealType.dinner,
          );

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 2);
      expect(calorieLogRepository.entries.single.isBundle, isTrue);
      expect(calorieLogRepository.entries.single.imageBase64, isNotNull);
      expect(calorieLogRepository.entries.single.bundleConsumedPortions, 2);
      expect(calorieLogRepository.entries.single.totalKcal, 200);
    },
  );

  test(
    'consumePreparedMeal stays alive without active listener during async save',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [_meal(id: 'meal-1', name: 'Lunch box', item: item)],
        saveDelay: const Duration(milliseconds: 20),
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(preparedMealsControllerProvider.future);
      final consumeFuture = container
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 1,
            mealType: MealType.lunch,
          );

      await Future<void>.delayed(const Duration(milliseconds: 1));

      final saved = await consumeFuture;
      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 3);
      expect(calorieLogRepository.entries.single.isBundle, isTrue);
    },
  );

  test(
    'consumePreparedMeal removes meal when remaining portions hit zero',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [
          _meal(
            id: 'meal-1',
            name: 'Lunch box',
            item: item,
          ).copyWith(remainingPortions: 1),
        ],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 1,
            mealType: MealType.dinner,
          );

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals, isEmpty);
      expect(
        container.read(preparedMealsControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test(
    'throwAwayPreparedMeal removes meal when remaining portions hit zero',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [
          _meal(
            id: 'meal-1',
            name: 'Lunch box',
            item: item,
          ).copyWith(remainingPortions: 1),
        ],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .throwAwayPreparedMeal(mealId: 'meal-1', discardedPortions: 1);

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals, isEmpty);
      expect(calorieLogRepository.entries, isEmpty);
      expect(
        container.read(preparedMealsControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test(
    'restorePreparedMealPortions increases remaining portions again',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [
          _meal(
            id: 'meal-1',
            name: 'Lunch box',
            item: item,
          ).copyWith(remainingPortions: 1),
        ],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final restored = await container
          .read(preparedMealsControllerProvider.notifier)
          .restorePreparedMealPortions(mealId: 'meal-1', portions: 1);

      expect(restored, isTrue);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 2);
    },
  );

  test('updatePreparedMealDetails updates meal name and image', () async {
    final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
    final existingMeal = _meal(id: 'meal-1', name: 'Lunch box', item: item);
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [item],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: [existingMeal],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(preparedMealRepository.dispose);
    addTearDown(calorieLogRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
        preparedMealRepositoryProvider.overrideWithValue(
          preparedMealRepository,
        ),
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    final saved = await container
        .read(preparedMealsControllerProvider.notifier)
        .updatePreparedMealDetails(
          mealId: existingMeal.id,
          name: 'Updated lunch box',
          imageChanged: true,
          imageBase64: base64Encode(<int>[9, 8, 7]),
        );

    expect(saved, isTrue);
    expect(preparedMealRepository.savedMeals.single.name, 'Updated lunch box');
    expect(
      preparedMealRepository.savedMeals.single.imageBase64,
      base64Encode(<int>[9, 8, 7]),
    );
    expect(
      preparedMealRepository.savedMeals.single.updatedAt,
      isNot(existingMeal.updatedAt),
    );
  });

  test('unbundlePreparedMeal restores remaining ingredient amounts', () async {
    final item = _item(id: 'rice', name: 'Rice', currentAmount: 50);
    final meal = _meal(
      id: 'meal-1',
      name: 'Lunch box',
      item: item,
    ).copyWith(remainingPortions: 2);
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [item],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: [meal],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(preparedMealRepository.dispose);
    addTearDown(calorieLogRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
        preparedMealRepositoryProvider.overrideWithValue(
          preparedMealRepository,
        ),
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    final saved = await container
        .read(preparedMealsControllerProvider.notifier)
        .unbundlePreparedMeal('meal-1');

    expect(saved, isTrue);
    expect(inventoryRepository.savedItems.single.currentAmount, 150);
    expect(preparedMealRepository.savedMeals, isEmpty);
  });

  test(
    'unbundlePreparedMeal recreates missing source items from snapshot',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 50);
      final meal = _meal(
        id: 'meal-1',
        name: 'Lunch box',
        item: item,
      ).copyWith(remainingPortions: 2);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: const <InventoryItem>[],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [meal],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
          preparedMealRepositoryProvider.overrideWithValue(
            preparedMealRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .unbundlePreparedMeal('meal-1');

      expect(saved, isTrue);
      expect(inventoryRepository.savedItems, hasLength(1));
      expect(inventoryRepository.savedItems.single.id, 'rice');
      expect(inventoryRepository.savedItems.single.currentAmount, 100);
      expect(inventoryRepository.savedItems.single.name, 'Rice');
    },
  );
}
