import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

/// The shelf the household chose per product, by [shoppingCatalogKey] of the
/// name.
typedef ShoppingShelfChoices = Map<String, ShoppingShelf>;

/// Where a product stands on the list and how it looks.
typedef ShoppingShelfPlacement = ({
  ShoppingShelf shelf,
  ShoppingItemIcon icon,
  bool isAssigned,
});

/// Places the product called [name]: the household's own choice wins, then
/// the catalog. A product neither knows stays under "Other", not assigned.
ShoppingShelfPlacement placeShoppingItem(
  String name,
  ShoppingShelfChoices choices,
) {
  final known = lookUpShoppingCatalog(name);
  final chosen = choices[shoppingCatalogKey(name)];
  if (chosen != null) {
    return (
      shelf: chosen,
      icon: known != null && known.shelf == chosen
          ? known.icon
          : shoppingShelfIcon(chosen),
      isAssigned: true,
    );
  }
  if (known != null) {
    return (shelf: known.shelf, icon: known.icon, isAssigned: true);
  }
  return (
    shelf: ShoppingShelf.other,
    icon: ShoppingItemIcon.other,
    isAssigned: false,
  );
}

/// Reads stored shelf choices. Throws a [FormatException] on a wrong shape;
/// a shelf this app does not know is left out, since a newer app may add
/// shelves.
ShoppingShelfChoices shoppingShelfChoicesFromJson(Map<String, dynamic> json) {
  final choices = json['choices'];
  if (choices is! Map) {
    throw FormatException('Expected a map of choices but got: $choices');
  }
  final byName = {for (final shelf in ShoppingShelf.values) shelf.name: shelf};
  return {
    for (final MapEntry(:key, :value) in choices.entries)
      if (key is String && value is String && byName[value] != null)
        key: byName[value]!,
  };
}

/// Stores [choices] in the shape [shoppingShelfChoicesFromJson] reads.
Map<String, dynamic> shoppingShelfChoicesToJson(ShoppingShelfChoices choices) =>
    {
      'choices': {
        for (final MapEntry(:key, :value) in choices.entries) key: value.name,
      },
    };

/// The entries in [items] by shelf, shelves in the order of the way through
/// the shop and only those with entries; inside a shelf the list order stays.
List<({ShoppingShelf shelf, List<T> items})> groupByShoppingShelf<T>(
  List<T> items,
  ShoppingShelf Function(T item) shelfOf,
) {
  final byShelf = <ShoppingShelf, List<T>>{};
  for (final item in items) {
    (byShelf[shelfOf(item)] ??= []).add(item);
  }
  return [
    for (final shelf in ShoppingShelf.values)
      if (byShelf[shelf] case final shelfItems?)
        (shelf: shelf, items: shelfItems),
  ];
}
