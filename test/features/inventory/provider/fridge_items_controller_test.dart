import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';

class _FakeFridgeItemRepository implements FridgeItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<FridgeItem>> Function() onReadAll;
  final StreamController<List<FridgeItem>> _watchController =
      StreamController<List<FridgeItem>>.broadcast();
  List<FridgeItem> savedItems = const <FridgeItem>[];
  Duration saveDelay = Duration.zero;
  bool saveAllShouldFail = false;
  bool saveAllShouldThrow = false;
  bool emitRealtimeOnSave = true;
  final Queue<bool> _saveResults = Queue<bool>();
  final Queue<Object> _saveErrors = Queue<Object>();

  @override
  Future<List<FridgeItem>> readAll() {
    return onReadAll();
  }

  @override
  Stream<List<FridgeItem>> watchAll() {
    return Stream<List<FridgeItem>>.multi((controller) {
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
  Future<bool> saveAll(List<FridgeItem> items) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }

    savedItems = List<FridgeItem>.from(items);

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
  Future<bool> appendAll(List<FridgeItem> items) async {
    return true;
  }

  Future<void> dispose() {
    return _watchController.close();
  }

  void emitWatchItems(List<FridgeItem> items) {
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

FridgeItem _item(String id) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

FridgeItem _amountItem(String id) {
  return FridgeItem(
    id: id,
    name: 'Juice',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1.0,
    initialAmount: 1000,
    currentAmount: 600,
    amountUnit: FridgeAmountUnit.milliliter,
  );
}

Future<void> _waitForAsyncPropagation() {
  return Future<void>.delayed(const Duration(milliseconds: 1));
}

ProviderSubscription<AsyncValue<List<FridgeItem>>> _keepControllerAlive(
  ProviderContainer container,
) {
  return container.listen(fridgeItemsControllerProvider, (previous, next) {});
}

void main() {
  test('build loads fridge items from repository', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final items = await container.read(fridgeItemsControllerProvider.future);

    expect(items, hasLength(1));
    expect(items.single.id, 'a');
  });

  test('refresh reloads updated repository state', () async {
    var phase = 0;
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async {
        if (phase == 0) {
          return <FridgeItem>[_item('a')];
        }
        return <FridgeItem>[_item('a'), _item('b')];
      },
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    phase = 1;
    await container.read(fridgeItemsControllerProvider.notifier).refresh();

    final refreshed = container.read(fridgeItemsControllerProvider).value;
    expect(refreshed, isNotNull);
    expect(refreshed, hasLength(2));
  });

  test('watchAll stream updates state in realtime', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final realtimeUpdate = Completer<void>();
    final subscription = container.listen(fridgeItemsControllerProvider, (
      _,
      next,
    ) {
      if (next.asData?.value.length == 2 && !realtimeUpdate.isCompleted) {
        realtimeUpdate.complete();
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    repository.emitWatchItems(<FridgeItem>[_item('a'), _item('b')]);
    await realtimeUpdate.future.timeout(const Duration(seconds: 1));

    final updated = container.read(fridgeItemsControllerProvider).asData?.value;
    expect(updated, isNotNull);
    expect(updated, hasLength(2));
  });

  test('watchAll stream error puts controller into AsyncError', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    final errorSeen = Completer<void>();
    final subscription = container.listen(fridgeItemsControllerProvider, (
      _,
      next,
    ) {
      if (next.hasError && !errorSeen.isCompleted) {
        errorSeen.complete();
      }
    });
    addTearDown(subscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final error = StateError('permission denied');
    repository.emitWatchError(error);
    await errorSeen.future.timeout(const Duration(seconds: 1));

    final state = container.read(fridgeItemsControllerProvider);
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
        overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await expectLater(
        container.read(fridgeItemsControllerProvider.future),
        throwsA(same(error)),
      );

      final state = container.read(fridgeItemsControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    },
  );

  test('logout swaps repository stream and clears inventory state', () async {
    var signedIn = true;
    final signedInRepository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    final signedOutRepository = _FakeFridgeItemRepository(
      onReadAll: () async => const <FridgeItem>[],
    );
    addTearDown(signedInRepository.dispose);
    addTearDown(signedOutRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        fridgeItemRepositoryProvider.overrideWith((ref) {
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

    await container.read(fridgeItemsControllerProvider.future);
    expect(
      container.read(fridgeItemsControllerProvider).asData?.value,
      hasLength(1),
    );

    signedIn = false;
    container.invalidate(fridgeItemRepositoryProvider);
    final itemsAfterLogout = await container.read(
      fridgeItemsControllerProvider.future,
    );

    expect(itemsAfterLogout, isEmpty);

    signedInRepository.emitWatchItems(<FridgeItem>[_item('old')]);
    await _waitForAsyncPropagation();
    expect(
      container.read(fridgeItemsControllerProvider).asData?.value,
      isEmpty,
    );

    signedOutRepository.emitWatchItems(<FridgeItem>[_item('new')]);
    await _waitForAsyncPropagation();
    expect(
      container.read(fridgeItemsControllerProvider).asData?.value,
      hasLength(1),
    );
    expect(
      container.read(fridgeItemsControllerProvider).asData?.value.single.id,
      'new',
    );
  });

  test('deleteItem removes item and updates state', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a'), _item('b')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final deleted = await container
        .read(fridgeItemsControllerProvider.notifier)
        .deleteItem('a');
    await _waitForAsyncPropagation();

    expect(deleted, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.id, 'b');
    expect(container.read(fridgeItemsControllerProvider).value, hasLength(1));
  });

  test(
    'deleteItem applies optimistic update and rolls back on save failure',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <FridgeItem>[_item('a'), _item('b')],
      );
      repository.saveDelay = const Duration(milliseconds: 20);
      repository.saveAllShouldFail = true;
      repository.emitRealtimeOnSave = false;
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(fridgeItemsControllerProvider.future);
      final deleteFuture = container
          .read(fridgeItemsControllerProvider.notifier)
          .deleteItem('a');
      await _waitForAsyncPropagation();

      final optimisticItems = container
          .read(fridgeItemsControllerProvider)
          .value;
      expect(optimisticItems, isNotNull);
      expect(optimisticItems, hasLength(1));
      expect(optimisticItems?.single.id, 'b');

      final deleted = await deleteFuture;
      expect(deleted, isFalse);

      final rolledBackItems = container
          .read(fridgeItemsControllerProvider)
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
      onReadAll: () async => <FridgeItem>[_item('a'), _item('b')],
    );
    repository.saveDelay = const Duration(milliseconds: 20);
    repository.saveAllShouldThrow = true;
    repository.emitRealtimeOnSave = false;
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final deleteFuture = container
        .read(fridgeItemsControllerProvider.notifier)
        .deleteItem('a');
    await _waitForAsyncPropagation();

    final optimisticItems = container.read(fridgeItemsControllerProvider).value;
    expect(optimisticItems, isNotNull);
    expect(optimisticItems, hasLength(1));
    expect(optimisticItems?.single.id, 'b');

    final deleted = await deleteFuture;
    expect(deleted, isFalse);

    final rolledBackItems = container.read(fridgeItemsControllerProvider).value;
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
        onReadAll: () async => <FridgeItem>[_item('a'), _item('b')],
      );
      repository.saveDelay = const Duration(milliseconds: 20);
      repository.emitRealtimeOnSave = false;
      repository.enqueueSaveResult(false);
      repository.enqueueSaveResult(true);
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(fridgeItemsControllerProvider.future);
      final deleteA = container
          .read(fridgeItemsControllerProvider.notifier)
          .deleteItem('a');
      await _waitForAsyncPropagation();
      final deleteB = container
          .read(fridgeItemsControllerProvider.notifier)
          .deleteItem('b');

      expect(await deleteA, isFalse);
      expect(await deleteB, isTrue);

      final finalItems = container.read(fridgeItemsControllerProvider).value;
      expect(finalItems, isNotNull);
      expect(finalItems, hasLength(1));
      expect(finalItems?.single.id, 'a');
    },
  );

  test('eatItem reduces quantity and keeps item if quantity remains', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a').copyWith(quantity: 3)],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final updated = await container
        .read(fridgeItemsControllerProvider.notifier)
        .eatItem('a', 2);
    await _waitForAsyncPropagation();

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.quantity, 1);
    expect(container.read(fridgeItemsControllerProvider).value, hasLength(1));
  });

  test(
    'eatItem clips amount and removes quantity-based item when over-limit',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <FridgeItem>[_item('a').copyWith(quantity: 3)],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(fridgeItemsControllerProvider.future);
      final removed = await container
          .read(fridgeItemsControllerProvider.notifier)
          .eatItem('a', 99);
      await _waitForAsyncPropagation();

      expect(removed, isTrue);
      expect(repository.savedItems, isEmpty);
      expect(container.read(fridgeItemsControllerProvider).value, isEmpty);
    },
  );

  test('throwAwayItem removes quantity-based item when depleted', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final removed = await container
        .read(fridgeItemsControllerProvider.notifier)
        .throwAwayItem('a', 1);
    await _waitForAsyncPropagation();

    expect(removed, isTrue);
    expect(repository.savedItems, isEmpty);
    expect(container.read(fridgeItemsControllerProvider).value, isEmpty);
  });

  test('throwAwayItem reduces amount-based stock and keeps item', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_amountItem('a')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controllerSubscription = _keepControllerAlive(container);
    addTearDown(controllerSubscription.close);

    await container.read(fridgeItemsControllerProvider.future);
    final updated = await container
        .read(fridgeItemsControllerProvider.notifier)
        .throwAwayItem('a', 200);
    await _waitForAsyncPropagation();

    expect(updated, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.currentAmount, 400);
    expect(repository.savedItems.single.quantity, 1);
  });

  test(
    'throwAwayItem clips amount and removes amount-based item when over-limit',
    () async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <FridgeItem>[_amountItem('a')],
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controllerSubscription = _keepControllerAlive(container);
      addTearDown(controllerSubscription.close);

      await container.read(fridgeItemsControllerProvider.future);
      final removed = await container
          .read(fridgeItemsControllerProvider.notifier)
          .throwAwayItem('a', 9999);
      await _waitForAsyncPropagation();

      expect(removed, isTrue);
      expect(repository.savedItems, isEmpty);
      expect(container.read(fridgeItemsControllerProvider).value, isEmpty);
    },
  );
}
