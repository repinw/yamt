import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_offer.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

ShoppingListItem _favorite(String name) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 0,
  estimatedUnitPrice: 0,
  isFavorite: true,
  isArchived: true,
);

ShoppingAddOffer _offer(
  String text, {
  List<ShoppingListItem> items = const [],
  List<ShoppingSuggestion> suggestions = const [],
  ShoppingShelfChoices choices = const {},
}) => shoppingAddOffer(
  text,
  items: items,
  suggestions: suggestions,
  catalog: shoppingCatalogIn('de'),
  choices: choices,
);

void main() {
  test('a name the catalog knows puts the new entry first', () {
    final offer = _offer('Milch');

    expect(offer.isTypedFirst, isTrue);
    expect(offer.hits, isNotEmpty);
    expect(offer.typed.isAssigned, isTrue);
  });

  test('a name known from a suggestion alone puts the new entry first', () {
    final offer = _offer(
      'Xyzzy',
      suggestions: const [ShoppingSuggestion(name: 'xyzzy', purchaseCount: 2)],
    );

    expect(offer.isTypedFirst, isTrue);
  });

  test('a word start puts the new entry after the hits', () {
    final offer = _offer('mi');

    expect(offer.isTypedFirst, isFalse);
    expect(offer.hits, isNotEmpty);
  });

  test('ideas come from the shelf of the first hit and leave out the typed '
      'text and the hits', () {
    final offer = _offer('Milch');
    final shown = {
      shoppingCatalogKey('Milch'),
      for (final (:hit, placement: _) in offer.hits)
        shoppingCatalogKey(hit.name),
    };

    expect(offer.ideaShelf, offer.hits.first.placement.shelf);
    expect(offer.ideas, isNotEmpty);
    for (final idea in offer.ideas) {
      expect(idea.shelf, offer.ideaShelf);
      expect(shown, isNot(contains(shoppingCatalogKey(idea.name))));
    }
  });

  test('empty text offers the favorites with their places and no ideas', () {
    final offer = _offer('', items: [_favorite('Milch'), _favorite('Brot')]);

    expect(
      [for (final (:hit, placement: _) in offer.hits) hit.name],
      ['Milch', 'Brot'],
    );
    expect(
      offer.hits.first.placement.shelf,
      lookUpShoppingCatalog('Milch')!.shelf,
    );
    expect(offer.isTypedFirst, isFalse);
    expect(offer.ideas, isEmpty);
  });

  test('a shelf the household chose changes the places', () {
    const chosen = ShoppingShelf.drinks;
    expect(lookUpShoppingCatalog('Milch')!.shelf, isNot(chosen));
    final choices = {shoppingCatalogKey('Milch'): chosen};

    final typed = _offer('Milch', choices: choices);
    final favorites = _offer('', items: [_favorite('Milch')], choices: choices);

    expect(typed.typed.shelf, chosen);
    expect(favorites.hits.single.placement.shelf, chosen);
  });
}
