import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
  bool appendShouldFail = false;
  bool appendShouldThrow = false;
  bool emitRealtimeOnAppend = true;
  final List<List<InventoryItem>> appendHistory = <List<InventoryItem>>[];

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    appendHistory.add(List<InventoryItem>.from(items));
    if (appendShouldThrow) {
      throw StateError('appendAll failed');
    }
    if (appendShouldFail) {
      return false;
    }

    for (final item in items) {
      final index = _items.indexWhere((current) => current.id == item.id);
      if (index < 0) {
        _items.add(item);
      } else {
        _items[index] = item;
      }
    }
    if (emitRealtimeOnAppend) {
      _controller.add(List<InventoryItem>.from(_items));
    }
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

  Future<void> dispose() {
    return _controller.close();
  }
}

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  final List<GlobalFoodItem> appendedItems = <GlobalFoodItem>[];

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async {
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return const <GlobalFoodItem>[];
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() {
    return const Stream<List<GlobalFoodItem>>.empty();
  }
}

class _FakeGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  final List<({String barcode, GlobalFoodItem globalFoodItem})>
  recordedSelections = <({String barcode, GlobalFoodItem globalFoodItem})>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return const <GlobalBarcodeCandidate>[];
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    recordedSelections.add((barcode: barcode, globalFoodItem: globalFoodItem));
  }
}

@Dependencies([InventoryItemsController])
ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(
    inventoryItemsControllerProvider,
    (previous, next) {},
  );
}

InventoryItem _item({
  required String id,
  String name = 'Milk',
  int quantity = 1,
  int initialQuantity = 1,
  String? weight,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    weight: weight,
  ).withDerivedAmount(weight: weight, quantity: quantity);
}

GlobalFoodItem _globalProduct({
  required String id,
  String name = 'Oat Drink',
  String? barcode,
  String? packageWeight,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    now: DateTime.parse('2026-04-07T12:00:00Z'),
    barcode: barcode,
    packageWeight: packageWeight,
  );
}

@Dependencies([InventoryItemsController])
void main() {
  test(
    'addItem publishes a new item without waiting for realtime sync',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: const <InventoryItem>[],
      )..emitRealtimeOnAppend = false;
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final addedItem = _item(id: 'a', name: 'Oat Milk');

      final saved = await container
          .read(inventoryItemsControllerProvider.notifier)
          .addItem(addedItem);

      expect(saved, isTrue);
      expect(repository.appendHistory.single, <InventoryItem>[addedItem]);
      expect(
        container.read(inventoryItemsControllerProvider).value,
        <InventoryItem>[addedItem],
      );
    },
  );

  test('addItem replaces an existing item with the same id', () async {
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_item(id: 'a')],
    )..emitRealtimeOnAppend = false;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final replacement = _item(id: 'a', name: 'Oat Drink', quantity: 2);

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .addItem(replacement);

    expect(saved, isTrue);
    final items = container.read(inventoryItemsControllerProvider).value;
    expect(items, hasLength(1));
    expect(items?.single, replacement);
  });

  test(
    'addItem rolls back optimistic state when append returns false',
    () async {
      final existingItem = _item(id: 'a');
      final repository =
          _FakeInventoryItemRepository(
              initialItems: <InventoryItem>[existingItem],
            )
            ..emitRealtimeOnAppend = false
            ..appendShouldFail = true;
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final addedItem = _item(id: 'b', name: 'Oat Milk');

      final saved = await container
          .read(inventoryItemsControllerProvider.notifier)
          .addItem(addedItem);

      expect(saved, isFalse);
      expect(repository.appendHistory.single, <InventoryItem>[addedItem]);
      expect(
        container.read(inventoryItemsControllerProvider).value,
        <InventoryItem>[existingItem],
      );
    },
  );

  test('addItem rolls back optimistic state when append throws', () async {
    final existingItem = _item(id: 'a');
    final repository =
        _FakeInventoryItemRepository(
            initialItems: <InventoryItem>[existingItem],
          )
          ..emitRealtimeOnAppend = false
          ..appendShouldThrow = true;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final addedItem = _item(id: 'b', name: 'Oat Milk');

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .addItem(addedItem);

    expect(saved, isFalse);
    expect(repository.appendHistory.single, <InventoryItem>[addedItem]);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      <InventoryItem>[existingItem],
    );
  });

  test(
    'buildInventoryItemEditSaveItem preserves stock for metadata-only edits',
    () {
      final consumedAt = DateTime.parse('2026-04-07T13:00:00Z');
      final currentItem = _item(
        id: 'a',
        quantity: 2,
        initialQuantity: 2,
        weight: '500g',
      ).copyWith(lastConsumedAt: consumedAt);
      final editedItem = currentItem.copyWith(
        name: 'Edited Milk',
        storeName: 'Edited Store',
        initialQuantity: 99,
        currentAmount: 123,
        lastConsumedAt: null,
      );

      final savedItem = buildInventoryItemEditSaveItem(
        currentItem: currentItem,
        editedItem: editedItem,
      );

      expect(savedItem.name, 'Edited Milk');
      expect(savedItem.storeName, 'Edited Store');
      expect(savedItem.quantity, currentItem.quantity);
      expect(savedItem.initialQuantity, currentItem.initialQuantity);
      expect(savedItem.initialAmount, currentItem.initialAmount);
      expect(savedItem.currentAmount, currentItem.currentAmount);
      expect(savedItem.amountScale, currentItem.amountScale);
      expect(savedItem.amountUnit, currentItem.amountUnit);
      expect(savedItem.lastConsumedAt, consumedAt);
    },
  );

  test('buildInventoryItemEditSaveItem accepts stock definition changes', () {
    final currentItem = _item(id: 'a', weight: '500g');
    final quantityChangedItem = currentItem
        .copyWith(name: 'Two Milks', initialQuantity: 2)
        .withDerivedAmount(weight: '500g', quantity: 2);
    final unitChangedItem = currentItem.withDerivedAmount(
      weight: '500ml',
      quantity: currentItem.quantity,
    );

    expect(
      buildInventoryItemEditSaveItem(
        currentItem: currentItem,
        editedItem: quantityChangedItem,
      ),
      quantityChangedItem,
    );
    expect(
      buildInventoryItemEditSaveItem(
        currentItem: currentItem,
        editedItem: unitChangedItem,
      ),
      unitChangedItem,
    );
  });

  test('updateItem replaces the matching inventory item', () async {
    final original = _item(id: 'a');
    final untouched = _item(id: 'b', name: 'Butter');
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[original, untouched],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = original
        .copyWith(name: 'Edited Milk', storeName: 'Edited Store')
        .withDerivedAmount(weight: '500g', quantity: 2);

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .updateItem(updated);

    expect(saved, isTrue);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      <InventoryItem>[updated, untouched],
    );
    expect(await repository.readAll(), <InventoryItem>[updated, untouched]);
  });

  test('updateItem rejects partially consumed items', () async {
    final consumedAt = DateTime.parse('2026-04-07T13:00:00Z');
    final original = _item(
      id: 'a',
      weight: '500g',
    ).copyWith(currentAmount: 250, lastConsumedAt: consumedAt);
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[original],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final editorResult = original
        .copyWith(name: 'Edited Milk', initialQuantity: original.quantity)
        .withDerivedAmount(
          weight: original.weight,
          quantity: original.quantity,
        );

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .updateItem(editorResult);

    expect(saved, isFalse);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      <InventoryItem>[original],
    );
    expect(await repository.readAll(), <InventoryItem>[original]);
  });

  test('updateItem rejects fully consumed items', () async {
    final consumedAt = DateTime.parse('2026-04-07T13:00:00Z');
    final original = _item(id: 'a', quantity: 0, initialQuantity: 1).copyWith(
      lastConsumedAt: consumedAt,
    );
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[original],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final editorResult = original.copyWith(
      name: 'Edited Milk',
      quantity: 1,
      initialQuantity: 1,
    );

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .updateItem(editorResult);

    expect(saved, isFalse);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      <InventoryItem>[original],
    );
    expect(await repository.readAll(), <InventoryItem>[original]);
  });

  test('updateItem returns false when the item no longer exists', () async {
    final existingItem = _item(id: 'a');
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[existingItem],
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = _keepControllerAlive(container);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);

    final saved = await container
        .read(inventoryItemsControllerProvider.notifier)
        .updateItem(_item(id: 'missing', name: 'Missing'));

    expect(saved, isFalse);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      <InventoryItem>[existingItem],
    );
    expect(await repository.readAll(), <InventoryItem>[existingItem]);
  });

  test(
    'stagePendingConsumption returns null for amount smaller than one',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[_item(id: 'a', quantity: 3)],
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption('a', 0);

      expect(pendingConsumption, isNull);
    },
  );

  test(
    'swapItemCandidate persists the resolved product and updates the item',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[
          _item(id: 'a', quantity: 2, initialQuantity: 2),
        ],
      );
      final globalRepository = _FakeGlobalFoodItemRepository();
      final barcodeRepository = _FakeGlobalBarcodeCandidateRepository();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          globalFoodItemRepositoryProvider.overrideWithValue(globalRepository),
          globalBarcodeCandidateRepositoryProvider.overrideWithValue(
            barcodeRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(inventoryItemsControllerProvider.future);

      final saved = await container
          .read(inventoryItemsControllerProvider.notifier)
          .swapItemCandidate(
            itemId: 'a',
            resolvedProduct: _globalProduct(
              id: 'off-4061458029995',
              barcode: '4061458029995',
              packageWeight: '1000 g',
            ),
            requiresGlobalPersistence: true,
            weight: '1000 g',
          );

      expect(saved, isTrue);
      expect(globalRepository.appendedItems, hasLength(1));

      final items = container.read(inventoryItemsControllerProvider).value;
      expect(items, hasLength(1));
      expect(items?.single.name, 'Oat Drink');
      expect(items?.single.globalFoodItemId, 'off-4061458029995');
      expect(items?.single.barcode, '4061458029995');
      expect(items?.single.weight, '1000 g');
      expect(items?.single.initialAmount, 2000);
      expect(items?.single.currentAmount, 2000);
      expect(barcodeRepository.recordedSelections, hasLength(1));
      expect(
        barcodeRepository.recordedSelections.single.barcode,
        '4061458029995',
      );
    },
  );

  test(
    'swapItemCandidate rejects items that were already partially consumed',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[
          _item(id: 'a', initialQuantity: 2),
        ],
      );
      final globalRepository = _FakeGlobalFoodItemRepository();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          globalFoodItemRepositoryProvider.overrideWithValue(globalRepository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepControllerAlive(container);
      addTearDown(subscription.close);

      await container.read(inventoryItemsControllerProvider.future);

      final saved = await container
          .read(inventoryItemsControllerProvider.notifier)
          .swapItemCandidate(
            itemId: 'a',
            resolvedProduct: _globalProduct(id: 'off-123', barcode: '123'),
            requiresGlobalPersistence: true,
            weight: '1000 g',
          );

      expect(saved, isFalse);
      expect(globalRepository.appendedItems, isEmpty);

      final items = container.read(inventoryItemsControllerProvider).value;
      expect(items?.single.name, 'Milk');
      expect(items?.single.globalFoodItemId, isNot('off-123'));
    },
  );
}
