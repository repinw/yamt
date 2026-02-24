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

  test('addItem returns false for empty name input', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    final added = controller.addItem(name: '   ');

    expect(added, isFalse);
    expect(container.read(shoppingListControllerProvider), isEmpty);
  });

  test('decrementQuantity removes item when quantity reaches zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(shoppingListControllerProvider.notifier);

    controller.addItem(name: 'Milk', quantity: 1);
    final itemId = container.read(shoppingListControllerProvider).single.id;

    controller.decrementQuantity(itemId);

    expect(container.read(shoppingListControllerProvider), isEmpty);
  });
}
