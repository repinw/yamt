import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion_queue.dart';

/// Why a product is offered in the add sheet.
enum ShoppingAddHitSource {
  /// A favorite or a product with a schedule.
  saved,

  /// Used up in the Vorrat.
  outOfStock,

  /// Almost empty in the Vorrat.
  lowStock,

  /// Bought several times.
  purchased,
}

/// A known product that matches what the user typed.
class ShoppingAddHit {
  /// Creates a hit.
  const new({
    required this.name,
    required this.brand,
    required this.source,
    this.purchaseCount = 0,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Why the product is offered.
  final ShoppingAddHitSource source;

  /// Recorded purchases, for [ShoppingAddHitSource.purchased].
  final int purchaseCount;

  /// Identifies the product, whatever its spelling.
  String get key => shoppingProductKey(name, brand);
}

/// The known products whose name contains [query], saved products first,
/// then the suggestions in their order; names that start with [query] come
/// before the others. Products that are on the list and still to buy stay
/// out; an entry without a brand counts for every brand of its name. A
/// product without a brand named exactly [query] stays out too, because the
/// typed text adds it already. An empty [query] offers the saved products
/// alone.
List<ShoppingAddHit> shoppingAddHits(
  String query, {
  required List<ShoppingListItem> items,
  required List<ShoppingSuggestion> suggestions,
}) {
  final needle = query.trim().toLowerCase();
  final hits = <String, ShoppingAddHit>{};
  final listed = <String>{};
  final listedAnyBrand = <String>{};
  for (final item in items) {
    final hit = ShoppingAddHit(
      name: item.name,
      brand: item.brand,
      source: ShoppingAddHitSource.saved,
    );
    if (item.isOpen) {
      listed.add(hit.key);
      if (item.brand?.trim().isEmpty ?? true) {
        listedAnyBrand.add(item.name.trim().toLowerCase());
      }
    } else if (item.isSaved) {
      hits[hit.key] = hit;
    }
  }
  bool isListed(ShoppingAddHit hit) =>
      listed.contains(hit.key) ||
      listedAnyBrand.contains(hit.name.trim().toLowerCase());
  final typed = shoppingProductKey(needle, null);
  if (needle.isNotEmpty) {
    for (final suggestion in suggestions) {
      final hit = ShoppingAddHit(
        name: suggestion.name,
        brand: suggestion.brand,
        source: suggestion.isOutOfStock
            ? ShoppingAddHitSource.outOfStock
            : suggestion.isLowStock
            ? ShoppingAddHitSource.lowStock
            : ShoppingAddHitSource.purchased,
        purchaseCount: suggestion.purchaseCount,
      );
      hits.putIfAbsent(hit.key, () => hit);
    }
  }
  final matching = [
    for (final hit in hits.values)
      if (!isListed(hit) &&
          hit.key != typed &&
          hit.name.toLowerCase().contains(needle))
        hit,
  ];
  return [
    ...matching.where((hit) => hit.name.toLowerCase().startsWith(needle)),
    ...matching.where((hit) => !hit.name.toLowerCase().startsWith(needle)),
  ];
}
