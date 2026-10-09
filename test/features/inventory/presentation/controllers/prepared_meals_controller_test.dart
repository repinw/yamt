import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

import '../../../../helpers/inventory_item_whole_list_writes.dart';
import '../../../calories/support/fake_calories_repositories.dart';

class _FakeInventoryItemRepository with InventoryItemWholeListWrites {
  new({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
  bool readShouldThrow = false;
  bool saveShouldFail = false;
  int readAllCount = 0;
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
    readAllCount += 1;
    if (readShouldThrow) {
      throw StateError('inventory-read-failed');
    }
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<List<InventoryItem>> storedItems() async =>
      List<InventoryItem>.from(_items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    if (saveShouldFail) {
      return false;
    }
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
  new({required List<PreparedMeal> initialMeals, this.throwOnSave = false})
    : _meals = List<PreparedMeal>.from(initialMeals);

  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _meals;
  List<PreparedMeal> savedMeals = const <PreparedMeal>[];
  bool saveShouldFail = false;
  bool throwOnSave;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_meals));
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
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
  Future<bool> save(PreparedMeal meal) => _saveAll([
    for (final stored in _meals)
      if (stored.id != meal.id) stored,
    meal,
  ]);

  @override
  Future<bool> delete(String mealId) => _saveAll([
    for (final stored in _meals)
      if (stored.id != mealId) stored,
  ]);

  Future<bool> _saveAll(List<PreparedMeal> meals) async {
    if (saveShouldFail) {
      return false;
    }
    if (throwOnSave) {
      throw Exception('prepared-meal-save-failed');
    }
    _meals = List<PreparedMeal>.from(meals);
    savedMeals = List<PreparedMeal>.from(meals);
    _controller.add(List<PreparedMeal>.from(_meals));
    return true;
  }

  void emitWatchMeals(List<PreparedMeal> meals) {
    _meals = List<PreparedMeal>.from(meals);
    _controller.add(List<PreparedMeal>.from(_meals));
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Future<void> dispose() => _controller.close();

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
}

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  bool saveShouldFail = false;
  final List<InventoryDiscardEvent> savedEvents = <InventoryDiscardEvent>[];

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return List<InventoryDiscardEvent>.from(savedEvents);
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    if (saveShouldFail) {
      return false;
    }
    savedEvents.add(event);
    return true;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    savedEvents.removeWhere((event) => event.id == eventId);
    return true;
  }
}

class _FakeInventoryActivityEventRepository
    implements InventoryActivityEventRepository {
  final List<InventoryActivityEvent> events = <InventoryActivityEvent>[];
  bool appendShouldFail = false;

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    if (appendShouldFail) {
      return false;
    }
    this.events.addAll(events);
    return true;
  }

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return Stream<List<InventoryActivityEvent>>.value(events);
  }
}

const _testActor = InventoryActivityActor(
  userId: 'user-1',
  displayName: 'Alex',
);

ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(preparedMealsControllerProvider, (previous, next) {});
}

Future<void> _waitForMeals(
  ProviderContainer container,
  bool Function(List<PreparedMeal> meals) predicate,
) async {
  final currentMeals = container
      .read(preparedMealsControllerProvider)
      .asData
      ?.value;
  if (currentMeals != null && predicate(currentMeals)) {
    return;
  }

  final ready = Completer<void>();
  late final ProviderSubscription<AsyncValue<List<PreparedMeal>>> subscription;
  subscription = container.listen(preparedMealsControllerProvider, (_, next) {
    final meals = next.asData?.value;
    if (meals == null || !predicate(meals) || ready.isCompleted) {
      return;
    }
    ready.complete();
    subscription.close();
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 1));
}

InventoryItem _item({
  required String id,
  required String name,
  int currentAmount = 300,
  int initialAmount = 300,
  int quantity = 1,
  int initialQuantity = 1,
  InventoryAmountUnit? amountUnit = InventoryAmountUnit.gram,
  GlobalFoodNutrition? nutrition = const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 200,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
  ),
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    nutrition: nutrition,
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
    imageAssetId: 'asset-$id',
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
  test('stale repository errors are ignored after repository swap', () async {
    var usesSharedRepository = true;
    final sharedItem = _item(id: 'rice', name: 'Rice');
    final sharedRepository = _FakePreparedMealRepository(
      initialMeals: <PreparedMeal>[
        _meal(id: 'shared-meal', name: 'Shared Meal', item: sharedItem),
      ],
    );
    final personalRepository = _FakePreparedMealRepository(
      initialMeals: const <PreparedMeal>[],
    );
    addTearDown(sharedRepository.dispose);
    addTearDown(personalRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        preparedMealRepositoryProvider.overrideWith((ref) {
          if (usesSharedRepository) {
            return sharedRepository;
          }
          return personalRepository;
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    usesSharedRepository = false;
    container.invalidate(preparedMealRepositoryProvider);

    final reloadedMeals = await container.read(
      preparedMealsControllerProvider.future,
    );
    expect(reloadedMeals, isEmpty);

    sharedRepository.emitWatchError(StateError('stale permission denied'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final stateAfterStaleError = container.read(
      preparedMealsControllerProvider,
    );
    expect(stateAfterStaleError.hasError, isFalse);
    expect(stateAfterStaleError.asData?.value, isEmpty);

    personalRepository.emitWatchMeals(<PreparedMeal>[
      _meal(id: 'personal-meal', name: 'Personal Meal', item: sharedItem),
    ]);
    await _waitForMeals(
      container,
      (meals) => meals.length == 1 && meals.single.id == 'personal-meal',
    );
  });

  test(
    'createPreparedMeal reduces inventory and saves a prepared meal',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(id: 'rice', name: 'Rice'),
          _item(id: 'beans', name: 'Beans', currentAmount: 250),
        ],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      final activityRepository = _FakeInventoryActivityEventRepository();
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
          inventoryActivityActorProvider.overrideWithValue(_testActor),
          inventoryActivityEventRepositoryProvider.overrideWithValue(
            activityRepository,
          ),
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
            imageAssetId: 'asset-created-meal',
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
      expect(
        preparedMealRepository.savedMeals.single.imageAssetId,
        'asset-created-meal',
      );
      expect(preparedMealRepository.savedMeals.single.components, hasLength(2));
      expect(
        activityRepository.events.map(
          (event) => (event.type, event.itemId, event.amount),
        ),
        <(InventoryActivityEventType, String, int)>[
          (InventoryActivityEventType.itemUsedInPreparedMeal, 'rice', 200),
          (InventoryActivityEventType.itemUsedInPreparedMeal, 'beans', 100),
        ],
      );
      expect(activityRepository.events.first.beforeCurrentAmount, 300);
      expect(activityRepository.events.first.afterCurrentAmount, 100);
      expect(inventoryRepository.readAllCount, 1);
    },
  );

  test(
    'createPreparedMeal restores inventory when prepared meal save throws',
    () async {
      final originalItems = [
        _item(id: 'rice', name: 'Rice'),
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
      // Two items written, then both written back.
      expect(inventoryRepository.saveHistory, hasLength(4));
      expect(inventoryRepository.savedItems[0].currentAmount, 300);
      expect(inventoryRepository.savedItems[1].currentAmount, 250);
      expect(
        container.read(preparedMealsControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test('createPreparedMeal still succeeds when activity save fails', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [_item(id: 'rice', name: 'Rice')],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: const <PreparedMeal>[],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final activityRepository = _FakeInventoryActivityEventRepository()
      ..appendShouldFail = true;
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
        inventoryActivityActorProvider.overrideWithValue(_testActor),
        inventoryActivityEventRepositoryProvider.overrideWithValue(
          activityRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    final result = await container
        .read(preparedMealsControllerProvider.notifier)
        .createPreparedMeal(
          name: 'Rice bowl',
          totalPortions: 2,
          items: const [PreparedMealItemInput(itemId: 'rice', usedAmount: 100)],
        );

    expect(result.isSuccess, isTrue);
    expect(preparedMealRepository.savedMeals, hasLength(1));
    expect(activityRepository.events, isEmpty);
  });

  test(
    'fillPreparedMealPendingIngredient keeps the remaining requirement',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(
            id: 'broth',
            name: 'Broth',
            currentAmount: 1000,
            amountUnit: InventoryAmountUnit.milliliter,
          ),
        ],
      );
      final existingMeal = PreparedMeal(
        id: 'meal-1',
        name: 'Soup',
        pendingRecipeIngredients: const <String>['1,5 l Broth'],
        totalPortions: 2,
        remainingPortions: 2,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: const <PreparedMealComponent>[],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [existingMeal],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      final activityRepository = _FakeInventoryActivityEventRepository();
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
          inventoryActivityActorProvider.overrideWithValue(_testActor),
          inventoryActivityEventRepositoryProvider.overrideWithValue(
            activityRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final filled = await container
          .read(preparedMealsControllerProvider.notifier)
          .fillPreparedMealPendingIngredient(
            mealId: 'meal-1',
            ingredient: '1,5 l Broth',
            inventoryItemIds: const <String>['broth'],
          );

      expect(filled, isTrue);
      expect(inventoryRepository.savedItems.single.currentAmount, 0);
      expect(preparedMealRepository.savedMeals.single.components, hasLength(1));
      expect(
        preparedMealRepository.savedMeals.single.pendingRecipeIngredients,
        const <String>['500 ml Broth'],
      );
      expect(
        activityRepository.events.single.type,
        InventoryActivityEventType.itemUsedInPreparedMeal,
      );
      expect(activityRepository.events.single.itemId, 'broth');
      expect(activityRepository.events.single.amount, 1000);
      expect(activityRepository.events.single.beforeCurrentAmount, 1000);
      expect(activityRepository.events.single.afterCurrentAmount, 0);
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
      final discardEventRepository = _FakeInventoryDiscardEventRepository();
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
          inventoryDiscardEventRepositoryProvider.overrideWithValue(
            discardEventRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .throwAwayPreparedMeal(
            mealId: 'meal-1',
            discardedPortions: 1,
            reason: InventoryDiscardReason.other,
          );

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals, isEmpty);
      expect(calorieLogRepository.entries, isEmpty);
      expect(discardEventRepository.savedEvents, hasLength(1));
      expect(
        container.read(preparedMealsControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test(
    'throwAwayPreparedMeal rolls back and returns false when event save fails',
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
      final discardEventRepository = _FakeInventoryDiscardEventRepository()
        ..saveShouldFail = true;
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
          inventoryDiscardEventRepositoryProvider.overrideWithValue(
            discardEventRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(preparedMealsControllerProvider.future);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .throwAwayPreparedMeal(
            mealId: 'meal-1',
            discardedPortions: 1,
            reason: InventoryDiscardReason.other,
          );

      expect(saved, isFalse);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 1);
      expect(discardEventRepository.savedEvents, isEmpty);
      // The meal list follows the stored meals through the stream.
      await pumpEventQueue();
      expect(
        container
            .read(preparedMealsControllerProvider)
            .asData
            ?.value
            .single
            .remainingPortions,
        1,
      );
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
          imageAssetId: 'asset-updated-meal',
        );

    expect(saved, isTrue);
    expect(preparedMealRepository.savedMeals.single.name, 'Updated lunch box');
    expect(
      preparedMealRepository.savedMeals.single.imageAssetId,
      'asset-updated-meal',
    );
    expect(
      preparedMealRepository.savedMeals.single.updatedAt,
      isNot(existingMeal.updatedAt),
    );
  });

  test(
    'updatePreparedMealDetails rolls back when meal save returns false',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final existingMeal = _meal(id: 'meal-1', name: 'Lunch box', item: item);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [existingMeal],
      )..saveShouldFail = true;
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
          .updatePreparedMealDetails(
            mealId: existingMeal.id,
            name: 'Updated lunch box',
          );

      expect(saved, isFalse);
      expect(
        container
            .read(preparedMealsControllerProvider)
            .asData
            ?.value
            .single
            .name,
        'Lunch box',
      );
    },
  );

  test(
    'updatePreparedMealDetails returns false when inventory read fails',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final existingMeal = _meal(id: 'meal-1', name: 'Lunch box', item: item);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      )..readShouldThrow = true;
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [existingMeal],
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
          .updatePreparedMealDetails(
            mealId: existingMeal.id,
            name: 'Updated lunch box',
          );

      expect(saved, isFalse);
      expect(inventoryRepository.readAllCount, 1);
      expect(preparedMealRepository.savedMeals, isEmpty);
    },
  );

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
    final activityRepository = _FakeInventoryActivityEventRepository();
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
        inventoryActivityActorProvider.overrideWithValue(_testActor),
        inventoryActivityEventRepositoryProvider.overrideWithValue(
          activityRepository,
        ),
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
    expect(
      activityRepository.events.single.type,
      InventoryActivityEventType.itemReturnedFromPreparedMeal,
    );
    expect(activityRepository.events.single.itemId, 'rice');
    expect(activityRepository.events.single.amount, 100);
    expect(activityRepository.events.single.beforeCurrentAmount, 50);
    expect(activityRepository.events.single.afterCurrentAmount, 150);
    expect(inventoryRepository.readAllCount, 1);
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
      final activityRepository = _FakeInventoryActivityEventRepository();
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
          inventoryActivityActorProvider.overrideWithValue(_testActor),
          inventoryActivityEventRepositoryProvider.overrideWithValue(
            activityRepository,
          ),
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
      expect(
        activityRepository.events.single.type,
        InventoryActivityEventType.itemReturnedFromPreparedMeal,
      );
      expect(activityRepository.events.single.itemId, 'rice');
      expect(activityRepository.events.single.amount, 100);
      expect(activityRepository.events.single.beforeCurrentAmount, isNull);
      expect(activityRepository.events.single.afterCurrentAmount, 100);
    },
  );

  test('refresh reloads the current repository stream', () async {
    final item = _item(id: 'rice', name: 'Rice');
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [item],
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
    preparedMealRepository.emitWatchMeals([
      _meal(id: 'meal-1', name: 'Lunch box', item: item),
    ]);
    await _waitForMeals(container, (meals) => meals.length == 1);

    await container.read(preparedMealsControllerProvider.notifier).refresh();

    final meals = container.read(preparedMealsControllerProvider).asData?.value;
    expect(meals?.single.id, 'meal-1');
  });

  test(
    'ignorePreparedMealPendingIngredient removes the pending ingredient',
    () async {
      final item = _item(id: 'rice', name: 'Rice');
      final existingMeal = _meal(
        id: 'meal-1',
        name: 'Lunch box',
        item: item,
      ).copyWith(pendingRecipeIngredients: const <String>['Sour cream']);
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
      final ignored = await container
          .read(preparedMealsControllerProvider.notifier)
          .ignorePreparedMealPendingIngredient(
            mealId: 'meal-1',
            ingredient: 'Sour cream',
          );

      expect(ignored, isTrue);
      expect(
        preparedMealRepository.savedMeals.single.pendingRecipeIngredients,
        isEmpty,
      );
    },
  );

  test('createPreparedMealsFromTemplateContainers saves split meals', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [
        _item(
          id: 'pasta',
          name: 'Pasta',
          currentAmount: 200,
          initialAmount: 200,
        ),
        _item(
          id: 'sauce',
          name: 'Sauce',
          currentAmount: 100,
          initialAmount: 100,
        ),
      ],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: const <PreparedMeal>[],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final activityRepository = _FakeInventoryActivityEventRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(preparedMealRepository.dispose);
    addTearDown(calorieLogRepository.dispose);

    final template = PreparedMeal(
      id: 'template-1',
      name: 'Spaghetti',
      recipeIngredients: const <String>['100 g pasta', '50 g sauce'],
      totalPortions: 4,
      remainingPortions: 4,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
        preparedMealRepositoryProvider.overrideWithValue(
          preparedMealRepository,
        ),
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        inventoryActivityActorProvider.overrideWithValue(_testActor),
        inventoryActivityEventRepositoryProvider.overrideWithValue(
          activityRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    final result = await container
        .read(preparedMealMutationServiceProvider)
        .createPreparedMealsFromTemplateContainers(
          template: template,
          totalPortions: 4,
          recipeIngredientAssignments: const <String, List<String>>{
            '100 g pasta': <String>['pasta'],
            '50 g sauce': <String>['sauce'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
          sourceKeysByIngredient: const <String, String>{
            '100 g pasta': 'row-pasta',
            '50 g sauce': 'row-sauce',
          },
          containers: const <PreparedMealContainerInput>[
            PreparedMealContainerInput(
              id: 'container-1',
              label: 'Pasta',
              totalPortions: 4,
              finalNetWeight: 700,
              sourceKeys: <String>['row-pasta'],
            ),
            PreparedMealContainerInput(
              id: 'container-2',
              label: 'Sauce',
              totalPortions: 4,
              finalNetWeight: 300,
              sourceKeys: <String>['row-sauce'],
            ),
          ],
        );

    expect(result.isSuccess, isTrue);
    expect(result.preparedMealIds, hasLength(2));
    expect(inventoryRepository.savedItems[0].currentAmount, 100);
    expect(inventoryRepository.savedItems[1].currentAmount, 50);
    expect(preparedMealRepository.savedMeals, hasLength(2));
    expect(preparedMealRepository.savedMeals[0].name, 'Spaghetti - Pasta');
    expect(preparedMealRepository.savedMeals[0].finalNetWeight, 700);
    expect(preparedMealRepository.savedMeals[1].name, 'Spaghetti - Sauce');
    expect(preparedMealRepository.savedMeals[1].finalNetWeight, 300);
    expect(
      activityRepository.events.map(
        (event) => (event.type, event.itemId, event.amount),
      ),
      <(InventoryActivityEventType, String, int)>[
        (InventoryActivityEventType.itemUsedInPreparedMeal, 'pasta', 100),
        (InventoryActivityEventType.itemUsedInPreparedMeal, 'sauce', 50),
      ],
    );
  });
}
