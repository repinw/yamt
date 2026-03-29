import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

class _FakeFridgeItemRepository implements InventoryItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<InventoryItem>> Function() onReadAll;
  final StreamController<List<InventoryItem>> _watchController =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> savedItems = const <InventoryItem>[];
  Duration saveDelay = Duration.zero;
  bool saveAllShouldFail = false;
  bool saveAllShouldThrow = false;
  bool emitRealtimeOnSave = true;
  final Queue<bool> _saveResults = Queue<bool>();
  final Queue<Object> _saveErrors = Queue<Object>();

  @override
  Future<List<InventoryItem>> readAll() {
    return onReadAll();
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      final watchSubscription = _watchController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      onReadAll().then(controller.add, onError: controller.addError);
      controller.onCancel = () {
        unawaited(watchSubscription.cancel());
      };
    });
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }

    savedItems = List<InventoryItem>.from(items);

    if (_saveErrors.isNotEmpty) {
      throw _saveErrors.removeFirst();
    }
    if (saveAllShouldThrow) {
      throw StateError('saveAll failed');
    }
    if (_saveResults.isNotEmpty) {
      return _saveResults.removeFirst();
    }
    if (saveAllShouldFail) {
      return false;
    }
    if (emitRealtimeOnSave) {
      _watchController.add(savedItems);
    }
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  Future<void> dispose() {
    return _watchController.close();
  }

  void emitWatchItems(List<InventoryItem> items) {
    _watchController.add(items);
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _watchController.addError(error, stackTrace);
  }

  void enqueueSaveResult(bool result) {
    _saveResults.add(result);
  }

  void enqueueSaveError(Object error) {
    _saveErrors.add(error);
  }
}

InventoryItem _item(String id) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

InventoryItem _amountItem(String id) {
  return InventoryItem.create(
    id: id,
    name: 'Juice',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1.0,
    initialAmount: 1000,
    currentAmount: 600,
    amountUnit: InventoryAmountUnit.milliliter,
  );
}

Future<void> _waitForItems(
  ProviderContainer container,
  bool Function(List<InventoryItem> items) predicate,
) async {
  final currentItems = container
      .read(inventoryItemsControllerProvider)
      .asData
      ?.value;
  if (currentItems != null && predicate(currentItems)) {
    return;
  }

  final ready = Completer<void>();
  late final ProviderSubscription<AsyncValue<List<InventoryItem>>> subscription;
  subscription = container.listen(inventoryItemsControllerProvider, (_, next) {
    final items = next.asData?.value;
    if (items == null || !predicate(items) || ready.isCompleted) {
      return;
    }
    ready.complete();
    subscription.close();
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 1));
}

ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(
    inventoryItemsControllerProvider,
    (previous, next) {},
  );
}

void main() {
  test('build loads fridge items from repository', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final items = await container.read(inventoryItemsControllerProvider.future);

    expect(items, hasLength(1));
    expect(items.single.id, 'a');
  });

  test('refresh reloads updated repository state', () async {
    var phase = 0;
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async {
        if (phase == 0) {
          return <InventoryItem>[_item('a')];
        }
        return <InventoryItem>[_item('a'), _item('b')];
      },
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    phase = 1;
    await container.read(inventoryItemsControllerProvider.notifier).refresh();

    final refreshed = container.read(inventoryItemsControllerProvider).value;
    expect(refreshed, isNotNull);
    expect(refreshed, hasLength(2));
  });

  test('watchAll stream updates state in realtime', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final realtimeUpdate = Completer<void>();
    final subscription = container.listen(inventoryItemsControllerProvider, (
      _,
      next,
    ) {
      if (next.asData?.value.length == 2 && !realtimeUpdate.isCompleted) {
        realtimeUpdate.complete();
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    repository.emitWatchItems(<InventoryItem>[_item('a'), _item('b')]);
    await realtimeUpdate.future.timeout(const Duration(seconds: 1));

    final updated = container
        .read(inventoryItemsControllerProvider)
        .asData
        ?.value;
    expect(updated, isNotNull);
    expect(updated, hasLength(2));
  });

  test('watchAll stream error puts controller into AsyncError', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final errorSeen = Completer<void>();
    final subscription = container.listen(inventoryItemsControllerProvider, (
      _,
      next,
    ) {
      if (next.hasError && !errorSeen.isCompleted) {
        errorSeen.complete();
      }
    });
    addTearDown(subscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final error = StateError('permission denied');
    repository.emitWatchError(error);
    await errorSeen.future.timeout(const Duration(seconds: 1));

    final state = container.read(inventoryItemsControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, same(error));
  });

  test(
    'initial watchAll stream error puts controller into AsyncError',
    () async {
      final error = StateError('permission denied');
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => throw error,
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await expectLater(
        container.read(inventoryItemsControllerProvider.future),
        throwsA(same(error)),
      );

      final state = container.read(inventoryItemsControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    },
  );

  test('logout swaps repository stream and clears inventory state', () async {
    var signedIn = true;
    final signedInRepository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    final signedOutRepository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
    );
    addTearDown(signedInRepository.dispose);
    addTearDown(signedOutRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWith((ref) {
          if (signedIn) {
            return signedInRepository;
          }
          return signedOutRepository;
        }),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    expect(
      container.read(inventoryItemsControllerProvider).asData?.value,
      hasLength(1),
    );

    signedIn = false;
    container.invalidate(inventoryItemRepositoryProvider);
    final itemsAfterLogout = await container.read(
      inventoryItemsControllerProvider.future,
    );

    expect(itemsAfterLogout, isEmpty);

    signedInRepository.emitWatchItems(<InventoryItem>[_item('old')]);
    await _waitForItems(container, (items) => items.isEmpty);
    expect(
      container.read(inventoryItemsControllerProvider).asData?.value,
      isEmpty,
    );

    signedOutRepository.emitWatchItems(<InventoryItem>[_item('new')]);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.id == 'new',
    );
    expect(
      container.read(inventoryItemsControllerProvider).asData?.value,
      hasLength(1),
    );
    expect(
      container.read(inventoryItemsControllerProvider).asData?.value.single.id,
      'new',
    );
  });

  test('deleteItem removes item and updates state', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final deleted = await container
        .read(inventoryItemsControllerProvider.notifier)
        .deleteItem('a');
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.id == 'b',
    );

    expect(deleted, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.id, 'b');
    expect(
      container.read(inventoryItemsControllerProvider).value,
      hasLength(1),
    );
  });

  test('undoLastDeletedItem restores deleted item at original index', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a'),
        _item('b'),
        _item('c'),
      ],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final deleted = await container
        .read(inventoryItemsControllerProvider.notifier)
        .deleteItem('b');
    await _waitForItems(
      container,
      (items) => items.length == 2 && items[0].id == 'a' && items[1].id == 'c',
    );

    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .undoLastDeletedItem();
    await _waitForItems(
      container,
      (items) =>
          items.length == 3 &&
          items[0].id == 'a' &&
          items[1].id == 'b' &&
          items[2].id == 'c',
    );

    expect(deleted, isTrue);
    expect(restored, isTrue);
    expect(repository.savedItems.map((item) => item.id).toList(), <String>[
      'a',
      'b',
      'c',
    ]);
  });

  test(
    'deleteItem applies optimistic update and rolls back on save failure',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
      );
      repository.saveDelay = const Duration(milliseconds: 20);
      repository.saveAllShouldFail = true;
      repository.emitRealtimeOnSave = false;
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final deleteFuture = container
          .read(inventoryItemsControllerProvider.notifier)
          .deleteItem('a');
      await _waitForItems(
        container,
        (items) => items.length == 1 && items.single.id == 'b',
      );

      final optimisticItems = container
          .read(inventoryItemsControllerProvider)
          .value;
      expect(optimisticItems, isNotNull);
      expect(optimisticItems, hasLength(1));
      expect(optimisticItems?.single.id, 'b');

      final deleted = await deleteFuture;
      expect(deleted, isFalse);

      final rolledBackItems = container
          .read(inventoryItemsControllerProvider)
          .value;
      expect(rolledBackItems, isNotNull);
      expect(rolledBackItems, hasLength(2));
      expect(
        rolledBackItems?.map((item) => item.id),
        containsAll(<String>['a', 'b']),
      );
    },
  );

  test('deleteItem rolls back on save exception and returns false', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
    );
    repository.saveDelay = const Duration(milliseconds: 20);
    repository.saveAllShouldThrow = true;
    repository.emitRealtimeOnSave = false;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final deleteFuture = container
        .read(inventoryItemsControllerProvider.notifier)
        .deleteItem('a');
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.id == 'b',
    );

    final optimisticItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(optimisticItems, isNotNull);
    expect(optimisticItems, hasLength(1));
    expect(optimisticItems?.single.id, 'b');

    final deleted = await deleteFuture;
    expect(deleted, isFalse);

    final rolledBackItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(rolledBackItems, isNotNull);
    expect(rolledBackItems, hasLength(2));
    expect(
      rolledBackItems?.map((item) => item.id),
      containsAll(<String>['a', 'b']),
    );
  });

  test(
    'sequential deletes keep consistent state when first save fails',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
      );
      repository.saveDelay = const Duration(milliseconds: 20);
      repository.emitRealtimeOnSave = false;
      repository.enqueueSaveResult(false);
      repository.enqueueSaveResult(true);
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final deleteA = container
          .read(inventoryItemsControllerProvider.notifier)
          .deleteItem('a');
      await _waitForItems(
        container,
        (items) => items.length == 1 && items.single.id == 'b',
      );
      final deleteB = container
          .read(inventoryItemsControllerProvider.notifier)
          .deleteItem('b');

      expect(await deleteA, isFalse);
      expect(await deleteB, isTrue);

      final finalItems = container.read(inventoryItemsControllerProvider).value;
      expect(finalItems, isNotNull);
      expect(finalItems, hasLength(1));
      expect(finalItems?.single.id, 'a');
    },
  );

  test('eatItem reduces quantity and keeps item if quantity remains', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a').copyWith(quantity: 3)],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem('a', 2);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.quantity == 1,
    );

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.quantity, 1);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      hasLength(1),
    );
  });

  test(
    'stagePendingConsumption updates visible stock without saving',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a').copyWith(quantity: 3),
        ],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption('a', 2);

      expect(pendingConsumption, isNotNull);
      expect(pendingConsumption?.amount, 2);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        1,
      );
      expect(repository.savedItems, isEmpty);
    },
  );

  test(
    'discardPendingConsumption restores visible stock without saving',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a').copyWith(quantity: 3),
        ],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption('a', 2);

      final discarded = await container
          .read(inventoryItemsControllerProvider.notifier)
          .discardPendingConsumption(pendingConsumption!.id);

      expect(discarded, isTrue);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        3,
      );
      expect(repository.savedItems, isEmpty);
    },
  );

  test(
    'finalizeCommittedPendingConsumption preserves latest realtime item data',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a').copyWith(quantity: 3, initialQuantity: 3),
        ],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption('a', 2);

      repository.emitWatchItems(<InventoryItem>[
        _item(
          'a',
        ).copyWith(quantity: 7, initialQuantity: 7, brand: 'Fresh brand'),
      ]);
      await _waitForItems(
        container,
        (items) =>
            items.length == 1 &&
            items.single.quantity == 5 &&
            items.single.brand == 'Fresh brand',
      );

      final finalized = await container
          .read(inventoryItemsControllerProvider.notifier)
          .finalizeCommittedPendingConsumption(
            draftId: pendingConsumption!.id,
            itemId: 'a',
            quantity: 5,
            currentAmount: 0,
          );

      expect(finalized, isTrue);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        5,
      );
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.brand,
        'Fresh brand',
      );
    },
  );

  test('eatItem rolls back quantity change when save throws', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a').copyWith(quantity: 3)],
    );
    repository.saveDelay = const Duration(milliseconds: 20);
    repository.saveAllShouldThrow = true;
    repository.emitRealtimeOnSave = false;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final eatFuture = container
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem('a', 1);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.quantity == 2,
    );

    final optimisticItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(optimisticItems, isNotNull);
    expect(optimisticItems, hasLength(1));
    expect(optimisticItems?.single.quantity, 2);

    final updated = await eatFuture;
    expect(updated, isFalse);

    final rolledBackItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(rolledBackItems, isNotNull);
    expect(rolledBackItems, hasLength(1));
    expect(rolledBackItems?.single.quantity, 3);
  });

  test('eatItem rolls back optimistic depletion when save throws', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a').copyWith(quantity: 1)],
    );
    repository.saveDelay = const Duration(milliseconds: 20);
    repository.saveAllShouldThrow = true;
    repository.emitRealtimeOnSave = false;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final eatFuture = container
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem('a', 1);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.quantity == 0,
    );

    final optimisticItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(optimisticItems, isNotNull);
    expect(optimisticItems, hasLength(1));
    expect(optimisticItems?.single.quantity, 0);

    final updated = await eatFuture;
    expect(updated, isFalse);

    final rolledBackItems = container
        .read(inventoryItemsControllerProvider)
        .value;
    expect(rolledBackItems, isNotNull);
    expect(rolledBackItems, hasLength(1));
    expect(rolledBackItems?.single.id, 'a');
    expect(rolledBackItems?.single.quantity, 1);
  });

  test(
    'eatItem clips amount and keeps quantity-based item at zero stock',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a').copyWith(quantity: 3),
        ],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final updated = await container
          .read(inventoryItemsControllerProvider.notifier)
          .eatItem('a', 99);
      await _waitForItems(
        container,
        (items) => items.length == 1 && items.single.quantity == 0,
      );

      expect(updated, isTrue);
      expect(repository.savedItems, hasLength(1));
      expect(repository.savedItems.single.quantity, 0);
      expect(
        container.read(inventoryItemsControllerProvider).value,
        hasLength(1),
      );
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        0,
      );
    },
  );

  test('throwAwayItem keeps quantity-based item when depleted', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .throwAwayItem('a', 1);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.quantity == 0,
    );

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.quantity, 0);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      hasLength(1),
    );
    expect(
      container.read(inventoryItemsControllerProvider).value?.single.quantity,
      0,
    );
  });

  test('throwAwayItem reduces amount-based stock and keeps item', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_amountItem('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .throwAwayItem('a', 200);
    await _waitForItems(
      container,
      (items) =>
          items.length == 1 &&
          items.single.currentAmount == 400 &&
          items.single.quantity == 1,
    );

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.currentAmount, 400);
    expect(repository.savedItems.single.quantity, 1);
  });

  test(
    'throwAwayItem clips amount and keeps amount-based item at zero stock',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[_amountItem('a')],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final updated = await container
          .read(inventoryItemsControllerProvider.notifier)
          .throwAwayItem('a', 9999);
      await _waitForItems(
        container,
        (items) =>
            items.length == 1 &&
            items.single.currentAmount == 0 &&
            items.single.quantity == 0,
      );

      expect(updated, isTrue);
      expect(repository.savedItems, hasLength(1));
      expect(repository.savedItems.single.currentAmount, 0);
      expect(repository.savedItems.single.quantity, 0);
      expect(
        container.read(inventoryItemsControllerProvider).value,
        hasLength(1),
      );
      expect(
        container
            .read(inventoryItemsControllerProvider)
            .value
            ?.single
            .currentAmount,
        0,
      );
    },
  );

  test('markBarcodeLookupRequested sets pending timestamp', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .markBarcodeLookupRequested('a');

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.barcodeLookupRequestedAt, isNotNull);
  });

  test('restoreConsumedItem increases quantity-based stock again', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a').copyWith(quantity: 0)],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .restoreConsumedItem('a', 1);

    expect(restored, isTrue);
    expect(repository.savedItems.single.quantity, 1);
    expect(
      container.read(inventoryItemsControllerProvider).value?.single.quantity,
      1,
    );
  });

  test('restoreConsumedItem increases amount-based stock again', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_amountItem('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .restoreConsumedItem('a', 200);

    expect(restored, isTrue);
    expect(repository.savedItems.single.currentAmount, 800);
    expect(repository.savedItems.single.quantity, 2);
  });

  test('setItemBarcode stores barcode and resolved timestamp', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .setItemBarcode(itemId: 'a', barcode: '4006381333931');

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.barcode, '4006381333931');
    expect(repository.savedItems.single.barcodeResolvedAt, isNotNull);
  });
}
