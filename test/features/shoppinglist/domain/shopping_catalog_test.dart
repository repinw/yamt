import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog_data.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

void main() {
  ShoppingShelf? shelfOf(String name) => lookUpShoppingCatalog(name)?.shelf;

  test('a known name finds its shelf and picture, whatever the case', () {
    final milk = lookUpShoppingCatalog('  MILCH ');

    expect(milk?.shelf, ShoppingShelf.chilled);
    expect(milk?.icon, ShoppingItemIcon.milk);
    expect(shelfOf('Bananen'), ShoppingShelf.produce);
    expect(shelfOf('Spülmittel'), ShoppingShelf.household);
  });

  test('a whole name wins over its words', () {
    expect(shelfOf('Gehackte Tomaten'), ShoppingShelf.pantry);
    expect(shelfOf('Tomaten'), ShoppingShelf.produce);
  });

  test('a word of the name counts, the last one first', () {
    expect(shelfOf('Milch 3,5 %'), ShoppingShelf.chilled);
    expect(shelfOf('Bio Eier Größe M'), ShoppingShelf.chilled);
    expect(shelfOf('rote Paprika'), ShoppingShelf.produce);
  });

  test('the product is the last word before a connector, not any word', () {
    expect(
      shelfOf('Cup a Soup Kartoffel Cremesuppe mit Knusper-Croutons'),
      ShoppingShelf.pantry,
    );
    expect(shelfOf('Yunmi Chilli Cheese Nuggets'), ShoppingShelf.frozen);
    expect(
      shelfOf('Thunfisch in Öl'),
      lookUpShoppingCatalog('Thunfisch')?.shelf,
    );
  });

  test('a compound word counts as its known end', () {
    expect(shelfOf('Vollkornnudeln'), ShoppingShelf.pantry);
    expect(shelfOf('Alpenmilch'), ShoppingShelf.chilled);
  });

  test('an unknown name and an empty name have no entry', () {
    expect(lookUpShoppingCatalog('Glühlampe E27'), isNull);
    expect(lookUpShoppingCatalog('   '), isNull);
  });

  test('no name stands in two groups', () {
    final keys = [
      for (final (_, _, :de, :en) in shoppingCatalogGroups)
        for (final name in {...de, ...en}) shoppingCatalogKey(name),
    ];

    expect(keys.toSet(), hasLength(keys.length));
  });
}
