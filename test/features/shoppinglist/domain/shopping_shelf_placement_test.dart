import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';

void main() {
  test('the household choice wins over the catalog, the picture follows '
      'the chosen shelf', () {
    final placement = placeShoppingItem('Milch', {
      'milch': ShoppingShelf.drinks,
    });

    expect(placement.shelf, ShoppingShelf.drinks);
    expect(placement.icon, shoppingShelfIcon(ShoppingShelf.drinks));
    expect(placement.isAssigned, isTrue);
  });

  test('a choice of the catalog shelf keeps the catalog picture', () {
    final placement = placeShoppingItem('Milch', {
      'milch': ShoppingShelf.chilled,
    });

    expect(placement.icon, ShoppingItemIcon.milk);
  });

  test('a product nobody knows is under other and not assigned', () {
    final placement = placeShoppingItem('Sternanis', const {});

    expect(placement.shelf, ShoppingShelf.other);
    expect(placement.isAssigned, isFalse);
  });

  test('choices go through JSON and unknown shelves are left out', () {
    final stored = shoppingShelfChoicesToJson({'tahini': ShoppingShelf.pantry});
    final read = shoppingShelfChoicesFromJson({
      'choices': {
        ...(stored['choices'] as Map<String, Object?>),
        'deko': 'garden',
      },
    });

    expect(read, {'tahini': ShoppingShelf.pantry});
    expect(
      () => shoppingShelfChoicesFromJson({'choices': 'tahini'}),
      throwsFormatException,
    );
  });

  test('grouping follows the way through the shop and keeps the list order '
      'inside a shelf', () {
    final groups = groupByShoppingShelf(
      ['soap', 'milk', 'apple', 'cream'],
      (item) => switch (item) {
        'soap' => ShoppingShelf.drugstore,
        'apple' => ShoppingShelf.produce,
        _ => ShoppingShelf.chilled,
      },
    );

    expect(
      [for (final group in groups) group.shelf],
      [ShoppingShelf.produce, ShoppingShelf.chilled, ShoppingShelf.drugstore],
    );
    expect(groups[1].items, ['milk', 'cream']);
  });
}
