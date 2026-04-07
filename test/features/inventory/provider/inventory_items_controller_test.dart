import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
  bool appendShouldFail = false;
  bool emitRealtimeOnAppend = true;
  final List<List<InventoryItem>> appendHistory = <List<InventoryItem>>[];

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    appendHistory.add(List<InventoryItem>.from(items));
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
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
  );
}

void main() {
  test(
    'addItem publishes a new item without waiting for realtime sync',
    () async {
      final repository = _FakeInventoryItemRepository(
        initialItems: const <InventoryItem>[],
      );
      repository.emitRealtimeOnAppend = false;
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
      initialItems: <InventoryItem>[_item(id: 'a', name: 'Milk')],
    );
    repository.emitRealtimeOnAppend = false;
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
}
