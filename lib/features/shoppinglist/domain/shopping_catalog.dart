import 'package:yamt/features/shoppinglist/domain/shopping_catalog_data.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// Where a known product stands and how it looks.
typedef ShoppingCatalogEntry = ({
  String name,
  ShoppingShelf shelf,
  ShoppingItemIcon icon,
});

final Map<String, ShoppingCatalogEntry> _byName = {
  for (final (shelf, icon, names) in shoppingCatalogGroups)
    for (final name in names)
      shoppingCatalogKey(name): (name: name, shelf: shelf, icon: icon),
};

/// All products the app knows from the start.
final List<ShoppingCatalogEntry> shoppingCatalog = List.unmodifiable(
  _byName.values,
);

/// [name] in the form the catalog compares: lower case, single spaces.
String shoppingCatalogKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final _wordSplit = RegExp("[^a-zäöüß']+");

/// The catalog entry for a product called [name], or null when the catalog
/// does not know it. The whole name counts first, then each word from the
/// last one on ("Gehackte Tomaten", "Milch 3,5 %"), and a word that ends in
/// a known product ("Vollkornnudeln") counts as that product.
ShoppingCatalogEntry? lookUpShoppingCatalog(String name) {
  final key = shoppingCatalogKey(name);
  if (key.isEmpty) return null;
  final whole = _byName[key];
  if (whole != null) return whole;
  final words = [
    for (final word in key.split(_wordSplit))
      if (word.length >= 2) word,
  ];
  for (final word in words.reversed) {
    final exact = _byName[word];
    if (exact != null) return exact;
  }
  for (final word in words.reversed) {
    final tail = _longestKnownTail(word);
    if (tail != null) return tail;
  }
  return null;
}

ShoppingCatalogEntry? _longestKnownTail(String word) {
  for (var start = 1; start <= word.length - 3; start++) {
    final entry = _byName[word.substring(start)];
    if (entry != null) return entry;
  }
  return null;
}
