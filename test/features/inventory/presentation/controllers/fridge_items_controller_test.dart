import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

import '../../../../helpers/inventory_item_whole_list_writes.dart';

class _FakeFridgeItemRepository with InventoryItemWholeListWrites {
  new({required this.onReadAll});

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
      unawaited(onReadAll().then(controller.add, onError: controller.addError));
      controller.onCancel = () {
        unawaited(watchSubscription.cancel());
      };
    });
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }

    savedItems = List<InventoryItem>.from(items);

    if (_saveErrors.isNotEmpty) {
      final error = _saveErrors.removeFirst();
      if (error is Error) {
        throw error;
      }
      if (error is Exception) {
        throw error;
      }
      throw StateError(error.toString());
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

  void enqueueSaveResult({required bool result}) {
    _saveResults.add(result);
  }

  void enqueueSaveError(Object error) {
    _saveErrors.add(error);
  }
}

class _RecordingShoppingListController extends ShoppingListController {
  ({String name, String? brand, int quantity, double estimatedUnitPrice})?
  _addItemInput;

  @override
  Future<List<ShoppingListItem>> build() async {
    return const <ShoppingListItem>[];
  }

  @override
  Future<ShoppingListRevert?> addItemWithRevert({
    required String name,
    String? brand,
    int quantity = 1,
    double estimatedUnitPrice = 0.0,
  }) async {
    _addItemInput = (
      name: name,
      brand: brand,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
    );
    return const <String, ShoppingListItem?>{};
  }
}

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  bool saveShouldFail = false;
  bool deleteShouldFail = false;
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
    if (deleteShouldFail) {
      return false;
    }
    savedEvents.removeWhere((event) => event.id == eventId);
    return true;
  }
}

InventoryItem _item(String id) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
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
    unitPrice: 1,
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

  test('stale repository errors are ignored after repository swap', () async {
    var usesSharedRepository = true;
    final sharedRepository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('shared')],
    );
    final personalRepository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
    );
    addTearDown(sharedRepository.dispose);
    addTearDown(personalRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWith((ref) {
          if (usesSharedRepository) {
            return sharedRepository;
          }
          return personalRepository;
        }),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    usesSharedRepository = false;
    container.invalidate(inventoryItemRepositoryProvider);

    final reloadedItems = await container.read(
      inventoryItemsControllerProvider.future,
    );
    expect(reloadedItems, isEmpty);

    sharedRepository.emitWatchError(StateError('stale permission denied'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final stateAfterStaleError = container.read(
      inventoryItemsControllerProvider,
    );
    expect(stateAfterStaleError.hasError, isFalse);
    expect(stateAfterStaleError.asData?.value, isEmpty);
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

    expect(deleted, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.id, 'b');
    expect(
      container.read(inventoryItemsControllerProvider).value,
      hasLength(1),
    );
  });

  test(
    'buyAgainItem forwards mapped values to shopping list controller',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => const <InventoryItem>[],
      );
      final shoppingListController = _RecordingShoppingListController();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          shoppingListControllerProvider.overrideWith(
            () => shoppingListController,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(inventoryItemsControllerProvider.notifier)
          .buyAgainItem(
            InventoryItem.create(
              id: 'buy-again-1',
              name: 'Milk',
              brand: 'Acme',
              entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
              storeName: 'Store',
              quantity: 0,
              initialQuantity: 0,
              unitPrice: 2.5,
            ),
          );

      expect(result, isNotNull);
      expect(shoppingListController._addItemInput, isNotNull);
      expect(shoppingListController._addItemInput!.name, 'Milk');
      expect(shoppingListController._addItemInput!.brand, 'Acme');
      expect(shoppingListController._addItemInput!.quantity, 1);
      expect(shoppingListController._addItemInput!.estimatedUnitPrice, 2.5);
    },
  );

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

  test('a failed delete leaves the list unchanged', () async {
    final repository =
        _FakeFridgeItemRepository(
            onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
          )
          ..saveDelay = const Duration(milliseconds: 20)
          ..saveAllShouldFail = true
          ..emitRealtimeOnSave = false;
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

    final deleted = await deleteFuture;
    expect(deleted, isFalse);

    final itemsAfter = container.read(inventoryItemsControllerProvider).value;
    expect(itemsAfter, isNotNull);
    expect(itemsAfter, hasLength(2));
    expect(itemsAfter?.map((item) => item.id), containsAll(<String>['a', 'b']));
  });

  test(
    'a delete that throws leaves the list unchanged and returns false',
    () async {
      final repository =
          _FakeFridgeItemRepository(
              onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
            )
            ..saveDelay = const Duration(milliseconds: 20)
            ..saveAllShouldThrow = true
            ..emitRealtimeOnSave = false;
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
      final shownLengths = <int>[];
      container.listen(
        inventoryItemsControllerProvider,
        (_, next) => shownLengths.add(next.value?.length ?? -1),
      );
      final deleteFuture = container
          .read(inventoryItemsControllerProvider.notifier)
          .deleteItem('a');

      final deleted = await deleteFuture;
      expect(deleted, isFalse);
      // The list never showed the delete that failed.
      expect(shownLengths, isNot(contains(1)));

      final itemsAfter = container.read(inventoryItemsControllerProvider).value;
      expect(itemsAfter, isNotNull);
      expect(itemsAfter, hasLength(2));
      expect(
        itemsAfter?.map((item) => item.id),
        containsAll(<String>['a', 'b']),
      );
    },
  );

  test(
    'sequential deletes keep consistent state when first save fails',
    () async {
      final repository =
          _FakeFridgeItemRepository(
              onReadAll: () async => <InventoryItem>[_item('a'), _item('b')],
            )
            ..saveDelay = const Duration(milliseconds: 20)
            ..emitRealtimeOnSave = false
            ..enqueueSaveResult(result: false)
            ..enqueueSaveResult(result: true);
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
    final consumedAt = DateTime.parse('2026-02-20T12:00:00Z');
    final updated = await container
        .read(inventoryItemsControllerProvider.notifier)
        .eatItemDetailed('a', 2, consumedAt: consumedAt);
    await _waitForItems(
      container,
      (items) => items.length == 1 && items.single.quantity == 1,
    );

    expect(updated, isNotNull);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.quantity, 1);
    expect(repository.savedItems.single.lastConsumedAt, consumedAt);
    expect(
      container.read(inventoryItemsControllerProvider).value,
      hasLength(1),
    );
  });

  test(
    'stagePendingConsumption keeps visible stock unchanged without saving',
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
        3,
      );
      expect(repository.savedItems, isEmpty);
    },
  );

  test('a finalized eat shows its new stock without a save', () async {
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
    final pending = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption('a', 2);
    final consumedAt = DateTime.parse('2026-02-20T12:00:00Z');

    container
        .read(inventoryPendingConsumptionStoreProvider)
        .finalize(
          id: pending!.id,
          itemId: 'a',
          quantity: 1,
          currentAmount: 0,
          consumedAt: consumedAt,
        );

    final item = container.read(inventoryItemsControllerProvider).value?.single;
    expect(item?.quantity, 1);
    expect(item?.lastConsumedAt, consumedAt);
    expect(repository.savedItems, isEmpty);
  });

  test('an eat that throws leaves the quantity unchanged', () async {
    final repository =
        _FakeFridgeItemRepository(
            onReadAll: () async => <InventoryItem>[
              _item('a').copyWith(quantity: 3),
            ],
          )
          ..saveDelay = const Duration(milliseconds: 20)
          ..saveAllShouldThrow = true
          ..emitRealtimeOnSave = false;
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
        .eatItemDetailed('a', 1);

    final updated = await eatFuture;
    expect(updated, isNull);

    final itemsAfter = container.read(inventoryItemsControllerProvider).value;
    expect(itemsAfter, isNotNull);
    expect(itemsAfter, hasLength(1));
    expect(itemsAfter?.single.quantity, 3);
  });

  test('an eat that throws leaves the item in stock', () async {
    final repository =
        _FakeFridgeItemRepository(
            onReadAll: () async => <InventoryItem>[
              _item('a').copyWith(quantity: 1),
            ],
          )
          ..saveDelay = const Duration(milliseconds: 20)
          ..saveAllShouldThrow = true
          ..emitRealtimeOnSave = false;
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
        .eatItemDetailed('a', 1);

    final updated = await eatFuture;
    expect(updated, isNull);

    final itemsAfter = container.read(inventoryItemsControllerProvider).value;
    expect(itemsAfter, isNotNull);
    expect(itemsAfter, hasLength(1));
    expect(itemsAfter?.single.id, 'a');
    expect(itemsAfter?.single.quantity, 1);
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
          .eatItemDetailed('a', 99);

      expect(updated, isNotNull);
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

  test('throwAwayItemDetailed returns the actual discarded amount', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_amountItem('a')],
    );
    final discardEventRepository = _FakeInventoryDiscardEventRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryDiscardEventRepositoryProvider.overrideWithValue(
          discardEventRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final result = await container
        .read(inventoryItemsControllerProvider.notifier)
        .throwAwayItemDetailed('a', 9999, InventoryDiscardReason.other);

    expect(result, isNotNull);
    expect(result?.removedAmount, 600);
    expect(discardEventRepository.savedEvents, hasLength(1));
    expect(
      discardEventRepository.savedEvents.single.id,
      result?.discardEventId,
    );
  });

  test('undoThrowAwayItem restores stock and removes discard event', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    final discardEventRepository = _FakeInventoryDiscardEventRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryDiscardEventRepositoryProvider.overrideWithValue(
          discardEventRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final discardResult = await container
        .read(inventoryItemsControllerProvider.notifier)
        .throwAwayItemDetailed('a', 1, InventoryDiscardReason.other);
    expect(discardResult, isNotNull);

    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .undoThrowAwayItem(
          itemId: 'a',
          amount: discardResult!.removedAmount,
          discardEventId: discardResult.discardEventId,
        );

    expect(restored, isTrue);
    expect(repository.savedItems.single.quantity, 1);
    expect(discardEventRepository.savedEvents, isEmpty);
  });

  test(
    'undoThrowAwayItem rolls stock back when deleting discard event fails',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[_item('a')],
      );
      final discardEventRepository = _FakeInventoryDiscardEventRepository()
        ..deleteShouldFail = true;
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          inventoryDiscardEventRepositoryProvider.overrideWithValue(
            discardEventRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final discardResult = await container
          .read(inventoryItemsControllerProvider.notifier)
          .throwAwayItemDetailed('a', 1, InventoryDiscardReason.other);
      expect(discardResult, isNotNull);

      final restored = await container
          .read(inventoryItemsControllerProvider.notifier)
          .undoThrowAwayItem(
            itemId: 'a',
            amount: discardResult!.removedAmount,
            discardEventId: discardResult.discardEventId,
          );

      expect(restored, isFalse);
      expect(repository.savedItems.single.quantity, 0);
      expect(
        container.read(inventoryItemsControllerProvider).value?.single.quantity,
        0,
      );
      expect(discardEventRepository.savedEvents, hasLength(1));
    },
  );

  test('undoThrowAwayItem rejects invalid undo arguments', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a')],
    );
    final discardEventRepository = _FakeInventoryDiscardEventRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryDiscardEventRepositoryProvider.overrideWithValue(
          discardEventRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .undoThrowAwayItem(itemId: 'a', amount: 0, discardEventId: '   ');

    expect(restored, isFalse);
    expect(repository.savedItems, isEmpty);
  });

  test('restoreConsumedItem increases quantity-based stock again', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a').copyWith(
          quantity: 0,
          lastConsumedAt: DateTime.parse('2026-02-20T12:00:00Z'),
        ),
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
    final restored = await container
        .read(inventoryItemsControllerProvider.notifier)
        .restoreConsumedItem('a', 1);

    expect(restored, isTrue);
    expect(repository.savedItems.single.quantity, 1);
    expect(repository.savedItems.single.lastConsumedAt, isNull);
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
}
