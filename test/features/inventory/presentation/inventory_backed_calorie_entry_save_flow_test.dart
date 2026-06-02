import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
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

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  PendingInventoryConsumption? pendingConsumption;
  CalorieEntry? entry;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    this.entry = entry;
    this.pendingConsumption = pendingConsumption;
    return const InventoryCalorieEntryCommitResult(
      itemId: 'inventory-1',
      quantity: 1,
      currentAmount: 0,
    );
  }
}

InventoryItem _inventoryItem() {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 3,
    initialQuantity: 3,
  );
}

CalorieEntry _entry() {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Milk',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 60,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 1.5,
    sourceInventoryItemId: 'inventory-1',
    sourceInventoryAmountToRestore: 2,
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

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  test(
    'save flow commits pending inventory consumption and finalizes state',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[_inventoryItem()],
      );
      final commitStore = _RecordingCommitStore();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
        ],
      );
      addTearDown(container.dispose);
      final inventorySubscription = _keepInventoryAlive(container);
      addTearDown(inventorySubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption('inventory-1', 2);

      final saved = await container
          .read(inventoryBackedCalorieEntrySaveFlowProvider)
          .saveEntry(
            entry: _entry(),
            pendingConsumptionId: pendingConsumption!.id,
          );

      expect(saved, isTrue);
      expect(commitStore.entry?.id, 'entry-1');
      expect(commitStore.pendingConsumption?.amount, 2);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        1,
      );
      expect(
        container
            .read(inventoryItemsControllerProvider)
            .value
            ?.single
            .lastConsumedAt,
        _entry().loggedAt,
      );
      expect(
        container
            .read(inventoryItemsControllerProvider.notifier)
            .hasPendingConsumption(pendingConsumption.id),
        isFalse,
      );
    },
  );

  test('save flow uses updated commit store dependency', () async {
    var commitStoreIndex = 0;
    final commitStoreIndexProvider = Provider<int>((ref) => commitStoreIndex);
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_inventoryItem()],
    );
    final firstCommitStore = _RecordingCommitStore();
    final secondCommitStore = _RecordingCommitStore();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryCalorieEntryCommitStoreProvider.overrideWith((ref) {
          final index = ref.watch(commitStoreIndexProvider);
          return index == 0 ? firstCommitStore : secondCommitStore;
        }),
      ],
    );
    addTearDown(container.dispose);
    final inventorySubscription = _keepInventoryAlive(container);
    addTearDown(inventorySubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    container.read(inventoryBackedCalorieEntrySaveFlowProvider);
    commitStoreIndex = 1;
    container.invalidate(commitStoreIndexProvider);

    final pendingConsumption = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption('inventory-1', 2);
    final saved = await container
        .read(inventoryBackedCalorieEntrySaveFlowProvider)
        .saveEntry(
          entry: _entry(),
          pendingConsumptionId: pendingConsumption!.id,
        );

    expect(saved, isTrue);
    expect(firstCommitStore.entry, isNull);
    expect(secondCommitStore.entry?.id, 'entry-1');
  });

  test('save flow reads live inventory controller when committing', () async {
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_inventoryItem()],
    );
    final commitStore = _RecordingCommitStore();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
          commitStore,
        ),
      ],
    );
    addTearDown(container.dispose);
    final inventorySubscription = _keepInventoryAlive(container);
    addTearDown(inventorySubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final flow = container.read(inventoryBackedCalorieEntrySaveFlowProvider);

    container.invalidate(inventoryItemsControllerProvider);
    await container.read(inventoryItemsControllerProvider.future);

    final pendingConsumption = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption('inventory-1', 2);
    final saved = await flow.saveEntry(
      entry: _entry(),
      pendingConsumptionId: pendingConsumption!.id,
    );

    expect(saved, isTrue);
    expect(commitStore.pendingConsumption?.id, pendingConsumption.id);
  });

  test(
    'save flow commits supplied pending consumption without lookup',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[_inventoryItem()],
      );
      final commitStore = _RecordingCommitStore();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
        ],
      );
      addTearDown(container.dispose);
      final inventorySubscription = _keepInventoryAlive(container);
      addTearDown(inventorySubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      const suppliedPendingConsumption = PendingInventoryConsumption(
        id: 'pending-from-caller',
        itemId: 'inventory-1',
        amount: 2,
      );
      final saved = await container
          .read(inventoryBackedCalorieEntrySaveFlowProvider)
          .saveEntry(
            entry: _entry(),
            pendingConsumptionId: suppliedPendingConsumption.id,
            pendingConsumption: suppliedPendingConsumption,
          );

      expect(saved, isTrue);
      expect(commitStore.pendingConsumption?.id, 'pending-from-caller');
    },
  );
}
