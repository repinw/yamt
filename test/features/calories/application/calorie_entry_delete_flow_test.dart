import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

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
    initialQuantity: 1,
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

PreparedMeal _meal({required String id, required int remainingPortions}) {
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
  required int consumedPortions,
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

ProviderSubscription<AsyncValue<List<PreparedMeal>>> _keepPreparedMealsAlive(
  ProviderContainer container,
) {
  return container.listen(preparedMealsControllerProvider, (_, _) {});
}

void main() {
  test(
    'delete flow restores inventory amount before deleting diary entry',
    () async {
      final calorieRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            id: 'entry-1',
            sourceInventoryItemId: 'inventory-1',
            sourceInventoryAmountToRestore: 250,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[_inventoryItem()],
      );
      addTearDown(calorieRepository.dispose);
      addTearDown(settingsRepository.dispose);
      addTearDown(inventoryRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(calorieRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          inventoryItemRepositoryProvider.overrideWithValue(
            inventoryRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final inventorySub = _keepInventoryAlive(container);
      final caloriesSub = _keepCaloriesAlive(container);
      addTearDown(inventorySub.close);
      addTearDown(caloriesSub.close);

      await container.read(inventoryItemsControllerProvider.future);
      await container.read(calorieEntriesControllerProvider.future);

      final result = await container
          .read(calorieEntryDeleteFlowProvider)
          .deleteEntry(
            entry: calorieRepository.entries.single,
            restoreToInventory: true,
          );

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(calorieRepository.entries, isEmpty);

      final restoredItems = container
          .read(inventoryItemsControllerProvider)
          .asData
          ?.value;
      expect(restoredItems, hasLength(1));
      expect(restoredItems?.single.currentAmount, 1000);
    },
  );

  test('delete flow fails when restore item is no longer available', () async {
    final calorieRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          id: 'entry-1',
          sourceInventoryItemId: 'missing-item',
          sourceInventoryAmountToRestore: 250,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_inventoryItem()],
    );
    addTearDown(calorieRepository.dispose);
    addTearDown(settingsRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(calorieRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
      ],
    );
    addTearDown(container.dispose);
    final inventorySub = _keepInventoryAlive(container);
    final caloriesSub = _keepCaloriesAlive(container);
    addTearDown(inventorySub.close);
    addTearDown(caloriesSub.close);

    await container.read(inventoryItemsControllerProvider.future);
    await container.read(calorieEntriesControllerProvider.future);

    final result = await container
        .read(calorieEntryDeleteFlowProvider)
        .deleteEntry(
          entry: calorieRepository.entries.single,
          restoreToInventory: true,
        );

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, CalorieEntryDeleteFailureReason.restoreFailed);
    expect(calorieRepository.entries, hasLength(1));
    expect(
      container
          .read(inventoryItemsControllerProvider)
          .asData
          ?.value
          .single
          .currentAmount,
      750,
    );
  });

  test('delete flow returns prepared meal bundle to inventory', () async {
    final calorieRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          id: 'entry-1',
          sourceMealId: 'meal-1',
          consumedPortions: 1,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_inventoryItem()],
    );
    final preparedMealRepository = _FakePreparedMealRepository(
      initialMeals: <PreparedMeal>[_meal(id: 'meal-1', remainingPortions: 1)],
    );
    addTearDown(calorieRepository.dispose);
    addTearDown(settingsRepository.dispose);
    addTearDown(inventoryRepository.dispose);
    addTearDown(preparedMealRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(calorieRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
        preparedMealRepositoryProvider.overrideWithValue(
          preparedMealRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final inventorySub = _keepInventoryAlive(container);
    final caloriesSub = _keepCaloriesAlive(container);
    final mealsSub = _keepPreparedMealsAlive(container);
    addTearDown(inventorySub.close);
    addTearDown(caloriesSub.close);
    addTearDown(mealsSub.close);

    await container.read(inventoryItemsControllerProvider.future);
    await container.read(preparedMealsControllerProvider.future);
    await container.read(calorieEntriesControllerProvider.future);

    final result = await container
        .read(calorieEntryDeleteFlowProvider)
        .deleteEntry(
          entry: calorieRepository.entries.single,
          restoreToInventory: true,
        );

    expect(result.isSuccess, isTrue);
    expect(result.restoredToInventory, isTrue);
    expect(calorieRepository.entries, isEmpty);
    expect(
      container
          .read(preparedMealsControllerProvider)
          .asData
          ?.value
          .single
          .remainingPortions,
      2,
    );
  });
}
