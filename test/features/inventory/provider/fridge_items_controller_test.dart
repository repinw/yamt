import 'dart:async';

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
    savedItems = List<FridgeItem>.from(items);
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

  test('deleteItem removes item and updates state', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a'), _item('b')],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(fridgeItemsControllerProvider.future);
    final deleted = await container
        .read(fridgeItemsControllerProvider.notifier)
        .deleteItem('a');

    expect(deleted, isTrue);
    expect(repository.savedItems, hasLength(1));
    expect(repository.savedItems.single.id, 'b');
    expect(container.read(fridgeItemsControllerProvider).value, hasLength(1));
  });

  test('eatItem reduces quantity and keeps item if quantity remains', () async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a').copyWith(quantity: 3)],
    );
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(fridgeItemsControllerProvider.future);
    final updated = await container
        .read(fridgeItemsControllerProvider.notifier)
        .eatItem('a', 2);

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

      await container.read(fridgeItemsControllerProvider.future);
      final removed = await container
          .read(fridgeItemsControllerProvider.notifier)
          .eatItem('a', 99);

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

    await container.read(fridgeItemsControllerProvider.future);
    final removed = await container
        .read(fridgeItemsControllerProvider.notifier)
        .throwAwayItem('a', 1);

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

    await container.read(fridgeItemsControllerProvider.future);
    final updated = await container
        .read(fridgeItemsControllerProvider.notifier)
        .throwAwayItem('a', 200);

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

      await container.read(fridgeItemsControllerProvider.future);
      final removed = await container
          .read(fridgeItemsControllerProvider.notifier)
          .throwAwayItem('a', 9999);

      expect(removed, isTrue);
      expect(repository.savedItems, isEmpty);
      expect(container.read(fridgeItemsControllerProvider).value, isEmpty);
    },
  );
}
