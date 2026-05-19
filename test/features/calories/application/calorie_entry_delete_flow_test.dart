import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_calorie_entry_delete_flow.dart';

import '../support/fake_calories_repositories.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items = <InventoryItem>[..._items, ...items];
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

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

  Future<void> dispose() => _controller.close();
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  _FakePreparedMealRepository({required List<PreparedMeal> initialMeals})
    : _meals = List<PreparedMeal>.from(initialMeals);

  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _meals;

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_meals);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    _meals = List<PreparedMeal>.from(meals);
    _controller.add(List<PreparedMeal>.from(_meals));
    return true;
  }

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

  Future<void> dispose() => _controller.close();
}

InventoryItem _inventoryItem() {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

CalorieEntry _entry({
  required String id,
  String? sourceInventoryItemId,
  int? sourceInventoryAmountToRestore,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Milk',
    mealType: MealType.breakfast,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.milliliters,
    per100Kcal: 60,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 1.5,
    sourceInventoryItemId: sourceInventoryItemId,
    sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
    loggedAt: DateTime(2026, 3, 27, 8),
    createdAt: DateTime(2026, 3, 27, 8),
    updatedAt: DateTime(2026, 3, 27, 8),
  );
}

PreparedMeal _meal({required String id, required num remainingPortions}) {
  final item = _inventoryItem();
  return PreparedMeal(
    id: id,
    name: 'Soup',
    totalPortions: 3,
    remainingPortions: remainingPortions,
    totalKcal: 300,
    totalProtein: 20,
    totalCarbs: 30,
    totalFat: 10,
    createdAt: DateTime.parse('2026-03-27T10:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T10:00:00Z'),
    components: <PreparedMealComponent>[
      PreparedMealComponent(
        inventoryItemId: item.id,
        name: item.name,
        brand: item.brand,
        imageUrl: item.imageUrl,
        usedAmount: 300,
        usedUnit: InventoryAmountUnit.milliliter,
        totalKcal: 300,
        totalProtein: 20,
        totalCarbs: 30,
        totalFat: 10,
        sourceItemSnapshot: item,
      ),
    ],
  );
}

CalorieEntry _bundleEntry({
  required String id,
  required String sourceMealId,
  required num consumedPortions,
}) {
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Soup',
    mealType: MealType.lunch,
    totalKcal: 100,
    totalProtein: 6,
    totalCarbs: 8,
    totalFat: 3,
    bundleSourcePreparedMealId: sourceMealId,
    bundleConsumedPortions: consumedPortions,
    bundleTotalPortions: 3,
    bundleComponents: const <CalorieEntryBundleComponent>[],
    loggedAt: DateTime(2026, 3, 27, 8),
    createdAt: DateTime(2026, 3, 27, 8),
    updatedAt: DateTime(2026, 3, 27, 8),
  );
}

@Dependencies([InventoryItemsController])
ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepInventoryAlive(
  ProviderContainer container,
) {
  return container.listen(inventoryItemsControllerProvider, (_, _) {});
}

ProviderSubscription<AsyncValue<List<CalorieEntry>>> _keepCaloriesAlive(
  ProviderContainer container,
) {
  return container.listen(calorieEntriesControllerProvider, (_, _) {});
}

@Dependencies([PreparedMealsController])
ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepPreparedMealsAlive(
  ProviderContainer container,
) {
  return container.listen(preparedMealsControllerProvider, (_, _) {});
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryCalorieEntryDeleteFlow,
])
class _DeleteFlowHarness {
  const _DeleteFlowHarness({
    required this.container,
    required this.calorieRepository,
  });

  final ProviderContainer container;
  final FakeCalorieLogRepository calorieRepository;

  Future<void> load({bool includePreparedMeals = false}) async {
    await container.read(inventoryItemsControllerProvider.future);
    if (includePreparedMeals) {
      await container.read(preparedMealsControllerProvider.future);
    }
    await container.read(calorieEntriesControllerProvider.future);
  }

  Future<CalorieEntryDeleteResult> deleteSingleEntry({
    required bool restoreToInventory,
  }) {
    return container
        .read(inventoryCalorieEntryDeleteFlowProvider)
        .deleteEntry(
          entry: calorieRepository.entries.single,
          restoreToInventory: restoreToInventory,
        );
  }

  int? get inventoryCurrentAmount {
    return container
        .read(inventoryItemsControllerProvider)
        .asData
        ?.value
        .single
        .currentAmount;
  }

  num? get preparedMealRemainingPortions {
    return container
        .read(preparedMealsControllerProvider)
        .asData
        ?.value
        .single
        .remainingPortions;
  }
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryCalorieEntryDeleteFlow,
])
_DeleteFlowHarness _buildDeleteFlowHarness({
  required List<CalorieEntry> entries,
  List<InventoryItem>? inventoryItems,
  List<PreparedMeal>? preparedMeals,
}) {
  final calorieRepository = FakeCalorieLogRepository(initialEntries: entries);
  final settingsRepository = FakeCalorieSettingsRepository();
  final inventoryRepository = _FakeInventoryItemRepository(
    initialItems: inventoryItems ?? <InventoryItem>[_inventoryItem()],
  );
  final preparedMealRepository = preparedMeals == null
      ? null
      : _FakePreparedMealRepository(initialMeals: preparedMeals);

  addTearDown(calorieRepository.dispose);
  addTearDown(settingsRepository.dispose);
  addTearDown(inventoryRepository.dispose);
  if (preparedMealRepository != null) {
    addTearDown(preparedMealRepository.dispose);
  }

  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(calorieRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
      if (preparedMealRepository != null)
        preparedMealRepositoryProvider.overrideWithValue(
          preparedMealRepository,
        ),
    ],
  );
  addTearDown(container.dispose);

  final inventorySub = _keepInventoryAlive(container);
  final caloriesSub = _keepCaloriesAlive(container);
  addTearDown(inventorySub.close);
  addTearDown(caloriesSub.close);
  if (preparedMealRepository != null) {
    final mealsSub = _keepPreparedMealsAlive(container);
    addTearDown(mealsSub.close);
  }

  return _DeleteFlowHarness(
    container: container,
    calorieRepository: calorieRepository,
  );
}

CalorieEntryDeleteFlow _deleteFlow({
  Future<bool> Function(String entryId)? deleteEntryById,
  Future<bool> Function(String itemId, int amount)? restoreConsumedItem,
  Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})?
  rollbackRestoredItem,
  Future<bool> Function(String itemId)? sourceInventoryItemExists,
  Future<bool> Function({required String mealId, required num portions})?
  restorePreparedMealPortions,
  Future<bool> Function({
    required String mealId,
    required num discardedPortions,
  })?
  rollbackRestoredPreparedMeal,
  Future<bool> Function(String mealId)? sourcePreparedMealExists,
}) {
  return CalorieEntryDeleteFlow(
    deleteEntryById: deleteEntryById ?? (entryId) async => true,
    restoreConsumedItem: restoreConsumedItem ?? (itemId, amount) async => true,
    rollbackRestoredItem:
        rollbackRestoredItem ?? (itemId, amount, {consumedAt}) async => true,
    sourceInventoryItemExists:
        sourceInventoryItemExists ?? (itemId) async => true,
    restorePreparedMealPortions:
        restorePreparedMealPortions ??
        ({required mealId, required portions}) async => true,
    rollbackRestoredPreparedMeal:
        rollbackRestoredPreparedMeal ??
        ({required mealId, required discardedPortions}) async => true,
    sourcePreparedMealExists:
        sourcePreparedMealExists ?? (mealId) async => true,
  );
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryCalorieEntryDeleteFlow,
])
void main() {
  test(
    'delete flow restores inventory amount before deleting diary entry',
    () async {
      final harness = _buildDeleteFlowHarness(
        entries: <CalorieEntry>[
          _entry(
            id: 'entry-1',
            sourceInventoryItemId: 'inventory-1',
            sourceInventoryAmountToRestore: 250,
          ),
        ],
      );

      await harness.load();

      final result = await harness.deleteSingleEntry(restoreToInventory: true);

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(harness.calorieRepository.entries, isEmpty);

      final restoredItems = harness.container
          .read(inventoryItemsControllerProvider)
          .asData
          ?.value;
      expect(restoredItems, hasLength(1));
      expect(restoredItems?.single.currentAmount, 1000);
    },
  );

  test('delete flow reports missing source when item is gone', () async {
    final harness = _buildDeleteFlowHarness(
      entries: <CalorieEntry>[
        _entry(
          id: 'entry-1',
          sourceInventoryItemId: 'missing-item',
          sourceInventoryAmountToRestore: 250,
        ),
      ],
    );

    await harness.load();

    final result = await harness.deleteSingleEntry(restoreToInventory: true);

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, CalorieEntryDeleteFailureReason.sourceMissing);
    expect(harness.calorieRepository.entries, hasLength(1));
    expect(harness.inventoryCurrentAmount, 750);
  });

  test('delete flow can delete diary entry when source item is gone', () async {
    final harness = _buildDeleteFlowHarness(
      entries: <CalorieEntry>[
        _entry(
          id: 'entry-1',
          sourceInventoryItemId: 'missing-item',
          sourceInventoryAmountToRestore: 250,
        ),
      ],
    );

    await harness.load();

    final result = await harness.deleteSingleEntry(restoreToInventory: false);

    expect(result.isSuccess, isTrue);
    expect(result.restoredToInventory, isFalse);
    expect(harness.calorieRepository.entries, isEmpty);
    expect(harness.inventoryCurrentAmount, 750);
  });

  test(
    'delete flow reports delete failure without inventory restore',
    () async {
      final result = await _deleteFlow(
        deleteEntryById: (entryId) async => false,
      ).deleteEntry(entry: _entry(id: 'entry-1'), restoreToInventory: false);

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.deleteFailed,
      );
    },
  );

  test(
    'delete flow rolls back inventory restore when diary delete fails',
    () async {
      var rolledBack = false;
      final entry = _entry(
        id: 'entry-1',
        sourceInventoryItemId: 'inventory-1',
        sourceInventoryAmountToRestore: 250,
      );

      final result = await _deleteFlow(
        deleteEntryById: (entryId) async => false,
        rollbackRestoredItem: (itemId, amount, {consumedAt}) async {
          rolledBack =
              itemId == 'inventory-1' &&
              amount == 250 &&
              consumedAt == entry.loggedAt;
          return true;
        },
      ).deleteEntry(entry: entry, restoreToInventory: true);

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.deleteFailed,
      );
      expect(rolledBack, isTrue);
    },
  );

  test('delete flow returns prepared meal bundle to inventory', () async {
    final harness = _buildDeleteFlowHarness(
      entries: <CalorieEntry>[
        _bundleEntry(
          id: 'entry-1',
          sourceMealId: 'meal-1',
          consumedPortions: 1,
        ),
      ],
      preparedMeals: <PreparedMeal>[
        _meal(id: 'meal-1', remainingPortions: 1),
      ],
    );

    await harness.load(includePreparedMeals: true);

    final result = await harness.deleteSingleEntry(restoreToInventory: true);

    expect(result.isSuccess, isTrue);
    expect(result.restoredToInventory, isTrue);
    expect(harness.calorieRepository.entries, isEmpty);
    expect(harness.preparedMealRemainingPortions, 2);
  });

  test(
    'delete flow returns fractional prepared meal bundle to inventory',
    () async {
      final harness = _buildDeleteFlowHarness(
        entries: <CalorieEntry>[
          _bundleEntry(
            id: 'entry-1',
            sourceMealId: 'meal-1',
            consumedPortions: 0.5,
          ),
        ],
        preparedMeals: <PreparedMeal>[
          _meal(id: 'meal-1', remainingPortions: 1),
        ],
      );

      await harness.load(includePreparedMeals: true);

      final result = await harness.deleteSingleEntry(restoreToInventory: true);

      expect(result.isSuccess, isTrue);
      expect(harness.preparedMealRemainingPortions, 1.5);
    },
  );

  test(
    'delete flow reports missing source when prepared meal is gone',
    () async {
      final result =
          await _deleteFlow(
            sourcePreparedMealExists: (mealId) async => false,
          ).deleteEntry(
            entry: _bundleEntry(
              id: 'entry-1',
              sourceMealId: 'missing-meal',
              consumedPortions: 1,
            ),
            restoreToInventory: true,
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
    },
  );

  test(
    'delete flow rolls back prepared meal restore when diary delete fails',
    () async {
      var rolledBack = false;
      final result =
          await _deleteFlow(
            deleteEntryById: (entryId) async => false,
            rollbackRestoredPreparedMeal:
                ({required mealId, required discardedPortions}) async {
                  rolledBack = mealId == 'meal-1' && discardedPortions == 1;
                  return true;
                },
          ).deleteEntry(
            entry: _bundleEntry(
              id: 'entry-1',
              sourceMealId: 'meal-1',
              consumedPortions: 1,
            ),
            restoreToInventory: true,
          );

      expect(result.isSuccess, isFalse);
      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.deleteFailed,
      );
      expect(rolledBack, isTrue);
    },
  );

  test(
    'delete flow restores a fully consumed prepared meal kept at zero portions',
    () async {
      final harness = _buildDeleteFlowHarness(
        entries: <CalorieEntry>[
          _bundleEntry(
            id: 'entry-1',
            sourceMealId: 'meal-1',
            consumedPortions: 1,
          ).copyWith(
            loggedAt: DateTime(2026, 4, 1, 12),
            createdAt: DateTime(2026, 4, 3, 10),
            updatedAt: DateTime(2026, 4, 3, 10),
          ),
        ],
        preparedMeals: <PreparedMeal>[
          _meal(id: 'meal-1', remainingPortions: 0),
        ],
      );

      await harness.load(includePreparedMeals: true);

      final result = await harness.deleteSingleEntry(restoreToInventory: true);

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(harness.calorieRepository.entries, isEmpty);
      expect(harness.preparedMealRemainingPortions, 1);
    },
  );
}
