import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_shopping_controller.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import '../../../shoppinglist/support/fake_shopping_list_repository.dart';

void main() {
  test('adds labels through shopping list controller', () async {
    final repository = FakeShoppingListRepository();
    final container = _container(repository);

    final result = await container
        .read(cookingFlowShoppingControllerProvider.notifier)
        .addLabels(<String>['Mehl', 'Milch']);

    expect(result, CookingFlowShoppingListActionResult.success);
    expect(repository.savedItems.map((item) => item.name), <String>[
      'Mehl',
      'Milch',
    ]);
  });

  test(
    'partial add failure returns failed and retry skips existing labels',
    () async {
      final repository = FakeShoppingListRepository()
        ..enqueueSaveResult(result: true)
        ..enqueueSaveResult(result: false)
        ..enqueueSaveResult(result: true);
      final container = _container(repository);
      final controller = container.read(
        cookingFlowShoppingControllerProvider.notifier,
      );

      final firstResult = await controller.addLabels(<String>['Mehl', 'Milch']);
      final retryResult = await controller.addLabels(<String>['Mehl', 'Milch']);

      expect(firstResult, CookingFlowShoppingListActionResult.failed);
      expect(retryResult, CookingFlowShoppingListActionResult.success);
      expect(repository.savedItems.map((item) => item.name), <String>[
        'Mehl',
        'Milch',
      ]);
      expect(repository.savedItems.map((item) => item.quantity), <int>[1, 1]);
    },
  );

  test('resolves labels by decrementing or removing matching rows', () async {
    final repository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _shoppingItem(id: 'flour', name: 'Mehl', quantity: 2),
        _shoppingItem(id: 'milk', name: 'Milch'),
      ],
    );
    final container = _container(repository);

    await container
        .read(cookingFlowShoppingControllerProvider.notifier)
        .resolveLabels(<String>['mehl', 'milch']);

    final itemsByName = <String, ShoppingListItem>{
      for (final item in repository.savedItems) item.name: item,
    };
    expect(itemsByName['Mehl']?.quantity, 1);
    expect(itemsByName.containsKey('Milch'), isFalse);
  });
}

ProviderContainer _container(FakeShoppingListRepository repository) {
  final container = ProviderContainer(
    overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  return container;
}

ShoppingListItem _shoppingItem({
  required String id,
  required String name,
  int quantity = 1,
}) {
  return ShoppingListItem(
    id: id,
    name: name,
    normalizedName: name,
    normalizedBrand: '',
    quantity: quantity,
    estimatedUnitPrice: 0,
  );
}
