import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

import '../../../calories/support/fake_calories_repositories.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
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
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
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

  void emitWatchMeals(List<PreparedMeal> meals) {
    _meals = List<PreparedMeal>.from(meals);
    _controller.add(List<PreparedMeal>.from(_meals));
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Future<void> dispose() => _controller.close();
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

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    this.events.addAll(events);
    return true;
  }

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return Stream<List<InventoryActivityEvent>>.value(events);
  }
}

class _FakePreparedMealCalorieEntryCommitStore
    implements PreparedMealCalorieEntryCommitStore {
  bool shouldSucceed = true;
  CalorieEntry? committedEntry;
  int commitCount = 0;

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) async {
    commitCount += 1;
    committedEntry = entry;
    return shouldSucceed;
  }
}

const _testActor = InventoryActivityActor(
  userId: 'user-1',
  displayName: 'Alex',
);

@Dependencies([PreparedMealsController])
ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(preparedMealsControllerProvider, (previous, next) {});
}

@Dependencies([PreparedMealsController])
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

@Dependencies([PreparedMealsController])
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
          (
            InventoryActivityEventType.itemUsedInPreparedMeal,
            'rice',
            200,
          ),
          (
            InventoryActivityEventType.itemUsedInPreparedMeal,
            'beans',
            100,
          ),
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
    'createPreparedMealFromTemplate parses fractions and decimals '
    'and keeps unsupported units pending',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(id: 'potatoes', name: 'Potatoes', currentAmount: 1000),
          _item(
            id: 'broth',
            name: 'Broth',
            currentAmount: 2000,
            amountUnit: InventoryAmountUnit.milliliter,
          ),
          _item(
            id: 'milk',
            name: 'Milk',
            currentAmount: 1000,
            amountUnit: InventoryAmountUnit.milliliter,
          ),
        ],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final template = PreparedMeal(
        id: 'template-1',
        name: 'Soup',
        recipeIngredients: const <String>[
          '1/2 kg Potatoes',
          '1,5 l Broth',
          '1 cup Milk',
        ],
        totalPortions: 1,
        remainingPortions: 1,
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
          .createPreparedMealFromTemplate(
            template: template,
            totalPortions: 1,
            recipeIngredientAssignments: const <String, List<String>>{
              '1/2 kg Potatoes': <String>['potatoes'],
              '1,5 l Broth': <String>['broth'],
              '1 cup Milk': <String>['milk'],
            },
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{},
          );

      expect(result.isSuccess, isTrue);
      expect(inventoryRepository.savedItems[0].currentAmount, 500);
      expect(inventoryRepository.savedItems[1].currentAmount, 500);
      expect(inventoryRepository.savedItems[2].currentAmount, 1000);
      expect(preparedMealRepository.savedMeals, hasLength(1));
      expect(preparedMealRepository.savedMeals.single.components, hasLength(2));
      expect(
        preparedMealRepository.savedMeals.single.pendingRecipeIngredients,
        const <String>['1 cup Milk'],
      );
    },
  );

  test(
    'createPreparedMealFromTemplate uses piece-to-gram conversions safely',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(
            id: 'carrots',
            name: 'Carrots',
            currentAmount: 2000,
            initialAmount: 2000,
          ),
        ],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final template = PreparedMeal(
        id: 'template-1',
        name: 'Carrot side',
        recipeIngredients: const <String>['2 Carrots'],
        totalPortions: 1,
        remainingPortions: 1,
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
          .createPreparedMealFromTemplate(
            template: template,
            totalPortions: 1,
            recipeIngredientAssignments: const <String, List<String>>{
              '2 Carrots': <String>['carrots'],
            },
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{
                  '2 Carrots': RecipeIngredientAmountConversion(
                    amountPerPiece: 100,
                    unit: InventoryAmountUnit.gram,
                  ),
                },
          );

      expect(result.isSuccess, isTrue);
      expect(inventoryRepository.savedItems.single.currentAmount, 1800);
      expect(preparedMealRepository.savedMeals.single.components, hasLength(1));
      expect(
        preparedMealRepository.savedMeals.single.components.single.usedAmount,
        200,
      );
      expect(
        preparedMealRepository.savedMeals.single.components.single.usedUnit,
        InventoryAmountUnit.gram,
      );
      expect(
        preparedMealRepository.savedMeals.single.pendingRecipeIngredients,
        isEmpty,
      );
    },
  );

  test('createPreparedMealFromTemplate does not consume measured items '
      'without piece conversion', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [
        _item(
          id: 'carrots',
          name: 'Carrots',
          currentAmount: 2000,
          initialAmount: 2000,
        ),
      ],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: const <PreparedMeal>[],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    addTearDown(inventoryRepository.dispose);
    addTearDown(preparedMealRepository.dispose);
    addTearDown(calorieLogRepository.dispose);

    final template = PreparedMeal(
      id: 'template-1',
      name: 'Carrot side',
      recipeIngredients: const <String>['2 Carrots'],
      totalPortions: 1,
      remainingPortions: 1,
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
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(preparedMealsControllerProvider.future);
    final result = await container
        .read(preparedMealsControllerProvider.notifier)
        .createPreparedMealFromTemplate(
          template: template,
          totalPortions: 1,
          recipeIngredientAssignments: const <String, List<String>>{
            '2 Carrots': <String>['carrots'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
        );

    expect(result.isSuccess, isTrue);
    expect(inventoryRepository.savedItems.single.currentAmount, 2000);
    expect(preparedMealRepository.savedMeals.single.components, isEmpty);
    expect(
      preparedMealRepository.savedMeals.single.pendingRecipeIngredients,
      const <String>['2 pc Carrots'],
    );
  });

  test(
    'createPreparedMealFromTemplate restores inventory when meal save throws',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [_item(id: 'rice', name: 'Rice', currentAmount: 500)],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: const <PreparedMeal>[],
        throwOnSave: true,
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(inventoryRepository.dispose);
      addTearDown(preparedMealRepository.dispose);
      addTearDown(calorieLogRepository.dispose);

      final template = PreparedMeal(
        id: 'template-1',
        name: 'Rice bowl',
        recipeIngredients: const <String>['500 g Rice'],
        totalPortions: 1,
        remainingPortions: 1,
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
          .createPreparedMealFromTemplate(
            template: template,
            totalPortions: 1,
            recipeIngredientAssignments: const <String, List<String>>{
              '500 g Rice': <String>['rice'],
            },
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{},
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        PreparedMealCreationFailureReason.mealSaveFailed,
      );
      expect(inventoryRepository.saveHistory, hasLength(2));
      expect(inventoryRepository.savedItems.single.currentAmount, 500);
    },
  );

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
      final loggedDay = DateTime(2026, 3, 20);
      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 0.5,
            mealType: MealType.dinner,
            loggedDay: loggedDay,
          );

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 3.5);
      expect(calorieLogRepository.entries.single.isBundle, isTrue);
      expect(calorieLogRepository.entries.single.imageAssetId, isNotNull);
      expect(calorieLogRepository.entries.single.bundleConsumedPortions, 0.5);
      expect(calorieLogRepository.entries.single.totalKcal, 50);
      expect(
        normalizeDiaryDay(calorieLogRepository.entries.single.loggedAt),
        loggedDay,
      );
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

  test('consumePreparedMeal returns false and restores portions when calorie '
      'save fails without atomic commit', () async {
    final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [item],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: [_meal(id: 'meal-1', name: 'Lunch box', item: item)],
    );
    final calorieLogRepository = FakeCalorieLogRepository()
      ..saveShouldFail = true;
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
        .consumePreparedMeal(
          mealId: 'meal-1',
          consumedPortions: 1,
          mealType: MealType.lunch,
        );

    expect(saved, isFalse);
    expect(preparedMealRepository.savedMeals.single.remainingPortions, 4);
    expect(calorieLogRepository.entries, isEmpty);
    expect(
      container
          .read(preparedMealsControllerProvider)
          .asData
          ?.value
          .single
          .remainingPortions,
      4,
    );
  });

  test('consumePreparedMeal uses atomic commit store when available', () async {
    final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [item],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: [_meal(id: 'meal-1', name: 'Lunch box', item: item)],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final commitStore = _FakePreparedMealCalorieEntryCommitStore();
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
        preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
          commitStore,
        ),
      ],
    );
    addTearDown(container.dispose);
    final mealsSubscription = _keepControllerAlive(container);
    addTearDown(mealsSubscription.close);
    final calorieSubscription = container.listen(
      calorieEntriesControllerProvider,
      (_, _) {},
    );
    addTearDown(calorieSubscription.close);

    final loggedDay = DateTime(2026, 3, 20);
    container.read(calorieDayControllerProvider.notifier).setDay(loggedDay);
    await container.read(preparedMealsControllerProvider.future);
    await container.read(calorieEntriesControllerProvider.future);

    final saved = await container
        .read(preparedMealsControllerProvider.notifier)
        .consumePreparedMeal(
          mealId: 'meal-1',
          consumedPortions: 1,
          mealType: MealType.dinner,
          loggedDay: loggedDay,
        );

    expect(saved, isTrue);
    expect(commitStore.commitCount, 1);
    expect(commitStore.committedEntry?.bundleSourcePreparedMealId, 'meal-1');
    expect(preparedMealRepository.savedMeals, isEmpty);
    expect(
      container
          .read(preparedMealsControllerProvider)
          .asData
          ?.value
          .single
          .remainingPortions,
      3,
    );
    expect(
      container.read(calorieEntriesControllerProvider).asData?.value,
      hasLength(1),
    );
  });

  test(
    'consumePreparedMeal restores local state when atomic commit fails',
    () async {
      final item = _item(id: 'rice', name: 'Rice', currentAmount: 100);
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [item],
      );
      final preparedMealRepository = _FakePreparedMealRepository(
        initialMeals: [_meal(id: 'meal-1', name: 'Lunch box', item: item)],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      final commitStore = _FakePreparedMealCalorieEntryCommitStore()
        ..shouldSucceed = false;
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
          preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
        ],
      );
      addTearDown(container.dispose);
      final mealsSubscription = _keepControllerAlive(container);
      addTearDown(mealsSubscription.close);
      final calorieSubscription = container.listen(
        calorieEntriesControllerProvider,
        (_, _) {},
      );
      addTearDown(calorieSubscription.close);

      final loggedDay = DateTime(2026, 3, 20);
      container.read(calorieDayControllerProvider.notifier).setDay(loggedDay);
      await container.read(preparedMealsControllerProvider.future);
      await container.read(calorieEntriesControllerProvider.future);

      final saved = await container
          .read(preparedMealsControllerProvider.notifier)
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 1,
            mealType: MealType.dinner,
            loggedDay: loggedDay,
          );

      expect(saved, isFalse);
      expect(commitStore.commitCount, 1);
      expect(preparedMealRepository.savedMeals, isEmpty);
      expect(
        container
            .read(preparedMealsControllerProvider)
            .asData
            ?.value
            .single
            .remainingPortions,
        4,
      );
      expect(
        container.read(calorieEntriesControllerProvider).asData?.value,
        isEmpty,
      );
    },
  );

  test(
    'consumePreparedMeal keeps meal with zero portions when fully consumed',
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
          .consumePreparedMeal(
            mealId: 'meal-1',
            consumedPortions: 1,
            mealType: MealType.dinner,
          );

      expect(saved, isTrue);
      expect(preparedMealRepository.savedMeals.single.remainingPortions, 0);
      expect(
        container
            .read(preparedMealsControllerProvider)
            .asData
            ?.value
            .single
            .remainingPortions,
        0,
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
}
