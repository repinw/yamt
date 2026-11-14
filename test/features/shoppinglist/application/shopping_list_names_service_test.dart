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

    await ShoppingListNamesService(
      repository,
    ).addMissing(['Mehl', '1 mittlere Zwiebel', '200 g Mehl', '2 Eier', ' ']);

    expect(
      repository.savedItems.map(
        (item) => (item.name, item.note, item.quantity),
      ),
      [('Mehl', null, 1), ('Zwiebel', '1 mittlere', 1), ('Eier', null, 2)],
    );
  });

  test(
    'a product on the private list still goes on the household list',
    () async {
      final repository = FakeShoppingListRepository(
        initialItems: [
          const ShoppingListItem(
            id: 'onion',
            name: 'Zwiebel',
            normalizedName: 'zwiebel',
            normalizedBrand: '',
            quantity: 1,
            estimatedUnitPrice: 0,
            isPrivate: true,
          ),
        ],
      );
      addTearDown(repository.dispose);

      await ShoppingListNamesService(repository).addMissing(['Zwiebel']);

      expect(repository.savedItems.map((item) => (item.name, item.isPrivate)), [
        ('Zwiebel', true),
        ('Zwiebel', false),
      ]);
    },
  );

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
