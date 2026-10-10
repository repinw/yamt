import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import '../support/fake_shopping_list_repository.dart';

const _flour = ShoppingListItem(
  id: 'flour',
  name: 'Mehl',
  normalizedName: 'mehl',
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
);

void main() {
  test('adds the names that are not on the list yet', () async {
    final repository = FakeShoppingListRepository(initialItems: [_flour]);
    addTearDown(repository.dispose);

    await ShoppingListNamesService(repository)
        .addMissing(['Mehl', '1 Zwiebel', ' ']);

    expect(repository.savedItems.map((item) => (item.name, item.quantity)), [
      ('Mehl', 1),
      ('1 Zwiebel', 1),
    ]);
  });

  test('names that are all listed need no write', () async {
    final repository = FakeShoppingListRepository(initialItems: [_flour])
      ..saveAllShouldFail = true;
    addTearDown(repository.dispose);

    await ShoppingListNamesService(repository).addMissing(['mehl']);
  });

  test('a failed read never replaces the list', () async {
    final repository = FakeShoppingListRepository(
      initialItems: [_flour],
      onReadAll: () => Future.error(StateError('offline')),
    );
    addTearDown(repository.dispose);

    await expectLater(
      ShoppingListNamesService(repository).addMissing(['Milch']),
      throwsStateError,
    );
    expect(repository.savedItems, isEmpty);
  });

  test('a failed save says so', () async {
    final repository = FakeShoppingListRepository()..saveAllShouldFail = true;
    addTearDown(repository.dispose);

    await expectLater(
      ShoppingListNamesService(repository).addMissing(['Mehl']),
      throwsStateError,
    );
  });
}
