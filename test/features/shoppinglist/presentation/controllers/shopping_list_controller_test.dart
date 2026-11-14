import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

import '../../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(
  String id, {
  String name = 'Milk',
  String? brand,
  int quantity = 1,
  double estimatedUnitPrice = 0,
  bool isDone = false,
}) {
  final normalizedBrand = (brand ?? '').trim().toLowerCase();
  return ShoppingListItem(
    id: id,
    name: name,
    brand: brand,
    normalizedName: name.trim().toLowerCase(),
    normalizedBrand: normalizedBrand,
    quantity: quantity,
    estimatedUnitPrice: estimatedUnitPrice,
    isDone: isDone,
  );
}

ProviderSubscription<AsyncValue<List<ShoppingListItem>>> _keepAlive(
  ProviderContainer container,
) {
  return container.listen(shoppingListControllerProvider, (previous, next) {});
}

Future<void> _waitForItems(
  ProviderContainer container,
  bool Function(List<ShoppingListItem> items) predicate,
) async {
  final currentItems = container
      .read(shoppingListControllerProvider)
      .asData
      ?.value;
  if (currentItems != null && predicate(currentItems)) {
    return;
  }

  final ready = Completer<void>();
  late final ProviderSubscription<AsyncValue<List<ShoppingListItem>>> sub;
  sub = container.listen(shoppingListControllerProvider, (_, next) {
    final items = next.asData?.value;
    if (items == null || !predicate(items) || ready.isCompleted) {
      return;
    }
    ready.complete();
    sub.close();
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 1));
}

Future<ProviderContainer> _createContainer(
  FakeShoppingListRepository repository, {
  AppUpdateStatus? updateStatus,
}) async {
  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      appUpdateStatusProvider.overrideWith(
        (ref) => updateStatus == null
            ? const Stream.empty()
            : Stream.value(updateStatus),
      ),
    ],
  );
  if (updateStatus != null) {
    final status = container.listen(appUpdateStatusProvider, (_, _) {});
    addTearDown(status.close);
    await container.read(appUpdateStatusProvider.future);
  }
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  final subscription = _keepAlive(container);
  addTearDown(subscription.close);
  await container.read(shoppingListControllerProvider.future);
  return container;
}

void main() {
  test('build loads shopping list items from repository', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a')],
    );
    final container = await _createContainer(repository);

    final items = container.read(shoppingListControllerProvider).asData?.value;

    expect(items, hasLength(1));
    expect(items?.single.id, 'a');
  });

  group('entries stored before the done flag', () {
    FakeShoppingListRepository unmigrated() =>
        FakeShoppingListRepository(initialItems: <ShoppingListItem>[_item('a')])
          ..holdsUnmigratedItems = true;

    test('are stored again once the app may rewrite them', () async {
      final repository = unmigrated();

      await _createContainer(repository, updateStatus: const AppUpToDate());

      expect(repository.savedItems.single.id, 'a');
    });

    test('stay as they are in an app below the minimum version', () async {
      final repository = unmigrated();

      await _createContainer(
        repository,
        updateStatus: const AppUpdateRequired(),
      );

      expect(repository.savedItems, isEmpty);
    });

    test('stay as they are until the update status is known', () async {
      final repository = unmigrated();

      final container = await _createContainer(repository);
      await container
          .read(shoppingListControllerProvider.notifier)
          .processDue();

      expect(repository.savedItems, isEmpty);
    });

    test(
      'are stored by the next schedule check after a missed start',
      () async {
        final repository = FakeShoppingListRepository(
          initialItems: <ShoppingListItem>[_item('a')],
        );
        final container = await _createContainer(
          repository,
          updateStatus: const AppUpToDate(),
        );
        repository.holdsUnmigratedItems = true;

        await container
            .read(shoppingListControllerProvider.notifier)
            .processDue();

        expect(repository.savedItems.single.id, 'a');
      },
    );
  });

  test('watchAll stream updates shopping list in realtime', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a')],
    );
    final container = await _createContainer(repository);

    repository.emitWatchItems(<ShoppingListItem>[_item('a'), _item('b')]);
    await _waitForItems(container, (items) => items.length == 2);

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(2));
  });

  test('initial stream error puts controller into AsyncError', () async {
    final error = StateError('permission denied');
    final repository = FakeShoppingListRepository(
      onReadAll: () async => throw error,
    );
    final container = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    final subscription = _keepAlive(container);
    addTearDown(subscription.close);

    await expectLater(
      container.read(shoppingListControllerProvider.future),
      throwsA(same(error)),
    );

    final state = container.read(shoppingListControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, same(error));
  });

  test(
    'build resolves empty when repository stream closes without items',
    () async {
      final repository = _EmptyStreamShoppingListRepository();
      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = _keepAlive(container);
      addTearDown(subscription.close);

      final items = await container
          .read(shoppingListControllerProvider.future)
          .timeout(const Duration(seconds: 1));

      expect(items, isEmpty);
    },
  );

  test('addItem merges duplicate items by normalized name and brand', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final firstAdded = await controller.addItem(name: 'Milk', brand: 'Acme');
    final secondAdded = await controller.addItem(
      name: ' milk ',
      brand: ' acme ',
    );
    await _waitForItems(container, (items) => items.length == 1);

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(firstAdded, isTrue);
    expect(secondAdded, isTrue);
    expect(items, hasLength(1));
    expect(items?.single.quantity, 2);
  });

  test('revert removes new entries and restores merged ones', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);
    await controller.addItem(name: 'Mehl');

    final merged = await controller.addItemWithRevert(name: 'Mehl');
    final added = await controller.addItemWithRevert(name: 'Milch');
    expect(
      container
          .read(shoppingListControllerProvider)
          .asData
          ?.value
          .map((item) => (item.name, item.quantity)),
      [('Mehl', 2), ('Milch', 1)],
    );

    expect(await controller.revert(added!), isTrue);
    expect(await controller.revert(merged!), isTrue);
    expect(
      container
          .read(shoppingListControllerProvider)
          .asData
          ?.value
          .map((item) => (item.name, item.quantity)),
      [('Mehl', 1)],
    );
  });

  test('addItem keeps separate rows for different brands', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', brand: 'Acme');
    await controller.addItem(name: 'Milk', brand: 'BioFarm');
    await _waitForItems(container, (items) => items.length == 2);

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(2));
  });

  test('addItem treats whitespace brand as empty and merges rows', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', brand: '   ');
    await controller.addItem(name: 'Milk');
    await _waitForItems(container, (items) => items.length == 1);

    final item = container.read(shoppingListControllerProvider).asData?.value;
    expect(item, hasLength(1));
    expect(item?.single.quantity, 2);
    expect(item?.single.normalizedBrand, isEmpty);
  });

  test('addItem returns false for empty name input', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final added = await controller.addItem(name: '   ');

    expect(added, isFalse);
    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, isEmpty);
  });

  test('addItem clamps negative quantity to one', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', quantity: -5);
    await _waitForItems(container, (items) => items.length == 1);

    final item = container.read(shoppingListControllerProvider).asData?.value;
    expect(item?.single.quantity, 1);
  });

  test('addItem keeps previous price when duplicate has zero price', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', estimatedUnitPrice: 2.49);
    await controller.addItem(name: 'Milk');

    final item = container.read(shoppingListControllerProvider).asData?.value;
    expect(item?.single.quantity, 2);
    expect(item?.single.estimatedUnitPrice, 2.49);
  });

  test('addItem updates price when duplicate has positive price', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', estimatedUnitPrice: 2.49);
    await controller.addItem(name: 'Milk', estimatedUnitPrice: 3.19);

    final item = container.read(shoppingListControllerProvider).asData?.value;
    expect(item?.single.quantity, 2);
    expect(item?.single.estimatedUnitPrice, 3.19);
  });

  test('incrementQuantity increases quantity for existing item', () async {
    final repository = FakeShoppingListRepository();
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);
    await controller.addItem(name: 'Milk', quantity: 2);
    final itemId = container
        .read(shoppingListControllerProvider)
        .asData
        ?.value
        .single
        .id;

    await controller.incrementQuantity(itemId!);

    final item = container.read(shoppingListControllerProvider).asData?.value;
    expect(item?.single.quantity, 3);
  });

  test('incrementQuantity keeps state unchanged for unknown id', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a', quantity: 2)],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.incrementQuantity('missing-id');

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.quantity, 2);
  });

  test('removeItem removes matching item id', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _item('a'),
        _item('b', name: 'Bread'),
      ],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.removeItem('a');

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.name, 'Bread');
  });

  test('decrementQuantity stops at one', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a', quantity: 2)],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.decrementQuantity('a');
    await controller.decrementQuantity('a');

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items?.single.quantity, 1);
    expect(items?.single.isDone, isFalse);
  });

  test('setDone puts an entry into the cart and back, quantity kept', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a', quantity: 3)],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);
    ShoppingListItem current() =>
        container.read(shoppingListControllerProvider).requireValue.single;

    expect(await controller.setDone('a', done: true), isTrue);
    expect((current().isDone, current().quantity), (true, 3));
    expect(repository.savedItems.single.isDone, isTrue);

    expect(await controller.setDone('a', done: false), isTrue);
    expect((current().isDone, current().quantity), (false, 3));
  });

  test('adding a product that is in the cart brings it back with the new '
      'quantity', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a', quantity: 3, isDone: true)],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.addItem(name: 'Milk', quantity: 2);

    final item = container
        .read(shoppingListControllerProvider)
        .requireValue
        .single;
    expect((item.id, item.isDone, item.quantity), ('a', false, 2));
  });

  test('decrementQuantity keeps state unchanged for unknown id', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a', quantity: 2)],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.decrementQuantity('missing-id');

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.quantity, 2);
  });

  test('finishTrip removes only the entries in the cart', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _item('a', quantity: 4, isDone: true),
        _item('b', name: 'Bread', quantity: 2),
      ],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.finishTrip();

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.name, 'Bread');
    expect(items?.single.quantity, 2);
  });

  test('save failure rolls back optimistic quantity update', () async {
    final repository =
        FakeShoppingListRepository(initialItems: <ShoppingListItem>[_item('a')])
          ..saveAllShouldFail = true
          ..emitRealtimeOnSave = false;
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final result = await controller.incrementQuantity('a');

    expect(result, isFalse);
    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.quantity, 1);
  });
}

class _EmptyStreamShoppingListRepository implements ShoppingListRepository {
  @override
  bool holdsUnmigratedItems = false;

  @override
  bool get privateUnreadable => false;

  @override
  Future<List<ShoppingListItem>> readAll() async {
    return const <ShoppingListItem>[];
  }

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) async {
    return false;
  }

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    return const Stream<List<ShoppingListItem>>.empty();
  }
}
