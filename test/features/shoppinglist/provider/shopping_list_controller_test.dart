import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import '../support/fake_shopping_list_repository.dart';

ShoppingListItem _item(
  String id, {
  String name = 'Milk',
  String? brand,
  int quantity = 1,
  double estimatedUnitPrice = 0,
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
  FakeShoppingListRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
  );
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

  test('decrementQuantity keeps item and sets quantity to zero', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[_item('a')],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.decrementQuantity('a');

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.quantity, 0);
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

  test('resolveItemsByIds decrements and removes in one save', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _item('a', quantity: 2),
        _item('b', name: 'Bread'),
        _item('c', name: 'Eggs', quantity: 3),
      ],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final result = await controller.resolveItemsByIds(<String>['a', 'b']);

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(result, isTrue);
    expect(items?.map((item) => item.id), <String>['a', 'c']);
    expect(items?.first.quantity, 1);
    expect(repository.savedItems.map((item) => item.id), <String>['a', 'c']);
  });

  test('clearCrossedOffItems removes only items with quantity zero', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _item('a', quantity: 0),
        _item('b', name: 'Bread', quantity: 2),
      ],
    );
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    await controller.clearCrossedOffItems();

    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.name, 'Bread');
    expect(items?.single.quantity, 2);
  });

  test('save failure rolls back optimistic quantity update', () async {
    final repository =
        FakeShoppingListRepository(
            initialItems: <ShoppingListItem>[_item('a')],
          )
          ..saveAllShouldFail = true
          ..emitRealtimeOnSave = false;
    final container = await _createContainer(repository);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final result = await controller.decrementQuantity('a');

    expect(result, isFalse);
    final items = container.read(shoppingListControllerProvider).asData?.value;
    expect(items, hasLength(1));
    expect(items?.single.quantity, 1);
  });
}
