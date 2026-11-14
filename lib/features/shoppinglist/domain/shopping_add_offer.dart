import 'package:yamt/features/shoppinglist/domain/shopping_add_hits.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

/// A product the add sheet offers, with the place it stands in the shop.
typedef ShoppingPlacedHit = ({
  ShoppingAddHit hit,
  ShoppingShelfPlacement placement,
});

/// What the add sheet offers for the typed text:
///
/// - `typed`: the place of the typed text as a new entry.
/// - `isTypedFirst`: whether the new entry comes before the hits.
/// - `hits`: the known products that match, each with its place; with
///   nothing typed, the favorites.
/// - `ideaShelf`: the shelf the ideas come from.
/// - `ideas`: more products from `ideaShelf`.
typedef ShoppingAddOffer = ({
  ShoppingShelfPlacement typed,
  bool isTypedFirst,
  List<ShoppingPlacedHit> hits,
  ShoppingShelf ideaShelf,
  List<ShoppingCatalogEntry> ideas,
});

/// What the add sheet offers for [text], from the [items] on the list, the
/// [suggestions] and the [catalog] in the user's language, placed with the
/// household's [choices]. The hits are [shoppingAddHits]. The ideas come
/// from the shelf of the first hit, or of [text] when nothing matches, and
/// leave out [text] and the hits; a [text] on no shelf without hits gets
/// none. A name the app knows (in the catalog, on the list, or suggested)
/// comes before the hits; a word start like "mi" is rarely the product, so
/// it comes after them. An empty [text] offers the favorites alone.
ShoppingAddOffer shoppingAddOffer(
  String text, {
  required List<ShoppingListItem> items,
  required List<ShoppingSuggestion> suggestions,
  required List<ShoppingCatalogEntry> catalog,
  required ShoppingShelfChoices choices,
}) {
  final hits = [
    for (final hit in shoppingAddHits(
      text,
      items: items,
      suggestions: suggestions,
      catalog: catalog,
    ))
      (hit: hit, placement: placeShoppingItem(hit.name, choices)),
  ];
  final typed = placeShoppingItem(text, choices);
  if (text.isEmpty) {
    return (
      typed: typed,
      isTypedFirst: false,
      hits: hits,
      ideaShelf: typed.shelf,
      ideas: const [],
    );
  }
  final ideaShelf = hits.isEmpty ? typed.shelf : hits.first.placement.shelf;
  final typedKey = shoppingCatalogKey(text);
  final ideas = typed.isAssigned || hits.isNotEmpty
      ? shoppingShelfIdeas(
          catalog,
          shelf: ideaShelf,
          items: items,
          shown: {
            typedKey,
            for (final (:hit, placement: _) in hits)
              shoppingCatalogKey(hit.name),
          },
        )
      : const <ShoppingCatalogEntry>[];
  final isTypedKnown =
      shoppingCatalogKey(lookUpShoppingCatalog(text)?.name ?? '') == typedKey ||
      [
        for (final item in items) item.name,
        for (final suggestion in suggestions) suggestion.name,
      ].any((name) => shoppingCatalogKey(name) == typedKey);
  return (
    typed: typed,
    isTypedFirst: isTypedKnown,
    hits: hits,
    ideaShelf: ideaShelf,
    ideas: ideas,
  );
}
