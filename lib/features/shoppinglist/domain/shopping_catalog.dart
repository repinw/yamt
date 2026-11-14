import 'package:yamt/features/shoppinglist/domain/shopping_catalog_data.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// Where a known product stands and how it looks.
typedef ShoppingCatalogEntry = ({
  String name,
  ShoppingShelf shelf,
  ShoppingItemIcon icon,
});

final Map<String, ShoppingCatalogEntry> _byName = {
  for (final (shelf, icon, :de, :en) in shoppingCatalogGroups)
    for (final name in [...de, ...en])
      shoppingCatalogKey(name): (name: name, shelf: shelf, icon: icon),
};

/// The products the app knows in the language with [languageCode], German
/// for every language but English, the more common ones of a shelf first.
/// Of two names that differ only in a short ending ("Banane", "Bananen") the
/// first one stays.
List<ShoppingCatalogEntry> shoppingCatalogIn(String languageCode) =>
    _byLanguage[languageCode == 'en' ? 'en' : 'de'] ??= List.unmodifiable(
      _catalogIn(languageCode),
    );

final _byLanguage = <String, List<ShoppingCatalogEntry>>{};

List<ShoppingCatalogEntry> _catalogIn(String languageCode) {
  final entries = <ShoppingCatalogEntry>[];
  for (final (shelf, icon, :de, :en) in shoppingCatalogGroups) {
    for (final name in languageCode == 'en' ? en : de) {
      if (entries.any((entry) => _sameWord(entry.name, name))) continue;
      entries.add((name: name, shelf: shelf, icon: icon));
    }
  }
  return entries;
}

/// Whether [a] and [b] are one word in singular and plural.
bool _sameWord(String a, String b) {
  final x = shoppingCatalogKey(a);
  final y = shoppingCatalogKey(b);
  final (shorter, longer) = x.length <= y.length ? (x, y) : (y, x);
  return longer.startsWith(shorter) && longer.length - shorter.length <= 2 ||
      _umlautFree(x) == _umlautFree(y);
}

String _umlautFree(String word) =>
    word.replaceAll('ä', 'a').replaceAll('ö', 'o').replaceAll('ü', 'u');

/// [name] in the form the catalog compares: lower case, single spaces.
String shoppingCatalogKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final _wordSplit = RegExp("[^a-zäöüß']+");

/// Words after which a product name only adds what comes with it ("Cup a
/// Soup Kartoffel Cremesuppe mit Croutons", "Thunfisch in Öl").
const _connectors = {'mit', 'und', 'ohne', 'in', 'aus', 'with', 'and'};

/// The catalog entry for a product called [name], or null when the catalog
/// does not know it. The whole name counts first. Otherwise the words up to
/// a connector like "mit" count, from the last one on, since the product
/// stands last in a name ("Gehackte Tomaten", "Milch 3,5 %"): each word as
/// a whole, then by a known end ("Cremesuppe" as "Suppe"), before the word
/// in front of it.
ShoppingCatalogEntry? lookUpShoppingCatalog(String name) {
  final key = shoppingCatalogKey(name);
  if (key.isEmpty) return null;
  final whole = _byName[key];
  if (whole != null) return whole;
  final words = <String>[];
  for (final word in key.split(_wordSplit)) {
    if (_connectors.contains(word) && words.isNotEmpty) break;
    if (word.length >= 2) words.add(word);
  }
  for (final word in words.reversed) {
    final entry = _byName[word] ?? _longestKnownTail(word);
    if (entry != null) return entry;
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
