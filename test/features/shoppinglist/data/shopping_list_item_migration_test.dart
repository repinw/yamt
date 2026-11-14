import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_migration.dart';

Map<String, dynamic> _stored({
  required int quantity,
  bool? archived,
  int? repeatEveryDays,
  int? repeatQuantity,
}) => <String, dynamic>{
  'id': 'a',
  'name': 'Milk',
  'quantity': quantity,
  'is_archived': ?archived,
  'repeat_every_days': ?repeatEveryDays,
  'repeat_quantity': ?repeatQuantity,
};

void main() {
  test('an entry that is still to buy is not done and keeps its quantity', () {
    final migrated = migrateStoredShoppingListItem(_stored(quantity: 3));

    expect((migrated['is_done'], migrated['quantity']), (false, 3));
  });

  test('a ticked-off entry becomes done with quantity one', () {
    final migrated = migrateStoredShoppingListItem(_stored(quantity: 0));

    expect((migrated['is_done'], migrated['quantity']), (true, 1));
  });

  test('a ticked-off entry with a schedule gets the schedule quantity', () {
    final migrated = migrateStoredShoppingListItem(
      _stored(quantity: 0, repeatEveryDays: 7, repeatQuantity: 4),
    );

    expect((migrated['is_done'], migrated['quantity']), (true, 4));
  });

  test('an archived saved product stays archived with quantity zero', () {
    final migrated = migrateStoredShoppingListItem(
      _stored(quantity: 0, archived: true, repeatEveryDays: 7),
    );

    expect((migrated['is_done'], migrated['quantity']), (false, 0));
  });

  test('a document with the done flag is returned as it is', () {
    final stored = {..._stored(quantity: 0), 'is_done': false};

    expect(migrateStoredShoppingListItem(stored), same(stored));
  });
}
