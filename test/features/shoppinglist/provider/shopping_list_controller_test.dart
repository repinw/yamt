import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

void main() {
  test('addItem merges duplicate items by normalized name and brand', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final firstAdded = controller.addItem(name: 'Milk', brand: 'Acme');
    final secondAdded = controller.addItem(name: ' milk ', brand: ' acme ');
    final items = container.read(shoppingListControllerProvider);

    expect(firstAdded, isTrue);
    expect(secondAdded, isTrue);
    expect(items, hasLength(1));
    expect(items.single.quantity, 2);
  });

  test('addItem keeps separate rows for same name with different brands', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', brand: 'Acme');
    controller.addItem(name: 'Milk', brand: 'BioFarm');
    final items = container.read(shoppingListControllerProvider);

    expect(items, hasLength(2));
  });

  test('addItem treats whitespace brand as empty and merges rows', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', brand: '   ');
    controller.addItem(name: 'Milk');
    final items = container.read(shoppingListControllerProvider);

    expect(items, hasLength(1));
    expect(items.single.quantity, 2);
    expect(items.single.normalizedBrand, isEmpty);
  });

  test('addItem returns false for empty name input', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final added = controller.addItem(name: '   ');

    expect(added, isFalse);
    expect(container.read(shoppingListControllerProvider), isEmpty);
  });

  test('addItem clamps negative quantity to one', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: -5);
    final item = container.read(shoppingListControllerProvider).single;

    expect(item.quantity, 1);
  });

  test('addItem keeps previous price when duplicate has zero price', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', estimatedUnitPrice: 2.49);
    controller.addItem(name: 'Milk', estimatedUnitPrice: 0);
    final item = container.read(shoppingListControllerProvider).single;

    expect(item.quantity, 2);
    expect(item.estimatedUnitPrice, 2.49);
  });

  test('addItem updates price when duplicate has positive price', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', estimatedUnitPrice: 2.49);
    controller.addItem(name: 'Milk', estimatedUnitPrice: 3.19);
    final item = container.read(shoppingListControllerProvider).single;

    expect(item.quantity, 2);
    expect(item.estimatedUnitPrice, 3.19);
  });

  test('incrementQuantity increases quantity for existing item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 2);
    final itemId = container.read(shoppingListControllerProvider).single.id;

    controller.incrementQuantity(itemId);
    final item = container.read(shoppingListControllerProvider).single;

    expect(item.quantity, 3);
  });

  test('incrementQuantity keeps state unchanged for unknown id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 2);
    final before = container.read(shoppingListControllerProvider);

    controller.incrementQuantity('missing-id');
    final after = container.read(shoppingListControllerProvider);

    expect(after, before);
  });

  test('removeItem removes matching item id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk');
    controller.addItem(name: 'Bread');
    final items = container.read(shoppingListControllerProvider);
    final milkId = items.firstWhere((item) => item.name == 'Milk').id;

    controller.removeItem(milkId);
    final nextItems = container.read(shoppingListControllerProvider);

    expect(nextItems, hasLength(1));
    expect(nextItems.single.name, 'Bread');
  });

  test('decrementQuantity keeps item and sets quantity to zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 1);
    final itemId = container.read(shoppingListControllerProvider).single.id;

    controller.decrementQuantity(itemId);
    final items = container.read(shoppingListControllerProvider);

    expect(items, hasLength(1));
    expect(items.single.quantity, 0);
  });

  test('decrementQuantity keeps state unchanged for unknown id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 2);
    final before = container.read(shoppingListControllerProvider);

    controller.decrementQuantity('missing-id');
    final after = container.read(shoppingListControllerProvider);

    expect(after, before);
  });

  test('clearCrossedOffItems removes only items with quantity zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 1);
    controller.addItem(name: 'Bread', quantity: 2);
    final items = container.read(shoppingListControllerProvider);
    final milkId = items.firstWhere((item) => item.name == 'Milk').id;

    controller.decrementQuantity(milkId);
    controller.clearCrossedOffItems();

    final nextItems = container.read(shoppingListControllerProvider);
    expect(nextItems, hasLength(1));
    expect(nextItems.single.name, 'Bread');
    expect(nextItems.single.quantity, 2);
  });
}
