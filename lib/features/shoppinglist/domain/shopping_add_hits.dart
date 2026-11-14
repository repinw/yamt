import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzywuzzy;
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
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

  /// Known to the app from the start.
  catalog,
}

/// Most catalog products the add sheet offers for one query.
const shoppingAddCatalogHitLimit = 6;

/// A known product that matches what the user typed.
class ShoppingAddHit {
  /// Creates a hit.
  const new({
    required this.name,
    required this.brand,
    required this.source,
    this.purchaseCount = 0,
    this.plannedFor,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Why the product is offered.
  final ShoppingAddHitSource source;

  /// Recorded purchases, for [ShoppingAddHitSource.purchased].
  final int purchaseCount;

  /// The planned meal a suggestion is for, kept on the entry it adds.
  final ShoppingPlannedMeal? plannedFor;

  /// Identifies the product, whatever its spelling.
  String get key => shoppingProductKey(name, brand);
}

/// The known products whose name matches [query]: saved products, the
/// suggestions, and up to [shoppingAddCatalogHitLimit] products of [catalog]
/// whose name no other hit has. A name matches at its start, at the start of
/// a word, or, from three letters on, inside a word ("milch" in
/// "Vollmilch"); the better match comes first, saved products lead each
/// part, and shorter names come before longer ones, so "mi" offers "Milch"
/// before "Mini Mix". Products
/// that are on the list and still to buy stay out; an entry without a brand
/// counts for every brand of its name. A product without a brand named
/// exactly [query] stays out too, because the typed text adds it already.
/// When nothing matches, a [query] of four letters or more is read with
/// typos ("Mlich" offers "Milch"). An empty [query] offers the saved
/// products alone.
List<ShoppingAddHit> shoppingAddHits(
  String query, {
  required List<ShoppingListItem> items,
  required List<ShoppingSuggestion> suggestions,
  List<ShoppingCatalogEntry> catalog = const [],
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
        plannedFor: suggestion.plannedFor,
      );
      hits.putIfAbsent(hit.key, () => hit);
    }
    var catalogHits = 0;
    for (final entry in catalog) {
      if (catalogHits == shoppingAddCatalogHitLimit) break;
      if (_matchOf(entry.name, needle) == null) continue;
      final hit = ShoppingAddHit(
        name: entry.name,
        brand: null,
        source: ShoppingAddHitSource.catalog,
      );
      final name = shoppingCatalogKey(entry.name);
      if (hits.values.any((other) => shoppingCatalogKey(other.name) == name)) {
        continue;
      }
      hits[hit.key] = hit;
      catalogHits++;
    }
  }
  final matching = [
    for (final hit in hits.values)
      if (!isListed(hit) &&
          hit.key != typed &&
          _matchOf(hit.name, needle) != null)
        hit,
  ];
  if (needle.isEmpty) return matching;
  if (matching.isEmpty) {
    return _typoHits(
      needle,
      [
        ...hits.values,
        for (final entry in catalog)
          ShoppingAddHit(
            name: entry.name,
            brand: null,
            source: ShoppingAddHitSource.catalog,
          ),
      ].where((hit) => !isListed(hit) && hit.key != typed),
    );
  }
  int rank(ShoppingAddHit hit) =>
      _matchOf(hit.name, needle)!.index * 2 +
      (hit.source == ShoppingAddHitSource.saved ? 0 : 1);
  // A stable sort keeps the order of equal hits.
  mergeSort(
    matching,
    compare: (a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.name.length.compareTo(b.name.length);
    },
  );
  return matching;
}

/// Shortest typed text that is read with typos.
const _typoMinLength = 4;

/// Least similarity, out of 100, of a word to the typed text with typos.
const _typoMinScore = 75;

/// When nothing matches, the [candidates] with a word, or the start of a
/// word, close to [needle] ("Mlich" for "Milch", "Banna" for "Bananen"),
/// the closest first, one per name, at most [shoppingAddCatalogHitLimit].
/// Short text gives none: it would match almost anything.
List<ShoppingAddHit> _typoHits(
  String needle,
  Iterable<ShoppingAddHit> candidates,
) {
  if (needle.length < _typoMinLength) return const [];
  final best = <String, ({ShoppingAddHit hit, int score})>{};
  for (final hit in candidates) {
    final words = hit.name.toLowerCase().split(_wordStart);
    var score = 0;
    for (final word in words) {
      if (word.isEmpty) continue;
      // The user may still be typing: compare the start of the word too.
      final start = word.length > needle.length
          ? word.substring(0, needle.length)
          : word;
      final next = max(
        fuzzywuzzy.ratio(needle, word),
        fuzzywuzzy.ratio(needle, start),
      );
      if (next > score) score = next;
    }
    if (score < _typoMinScore) continue;
    final name = shoppingCatalogKey(hit.name);
    final known = best[name];
    // A saved or suggested product comes before the catalog one of its name.
    if (known == null || score > known.score) {
      best[name] = (hit: hit, score: score);
    }
  }
  final ranked = best.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return [
    for (final entry in ranked.take(shoppingAddCatalogHitLimit)) entry.hit,
  ];
}

/// Where the typed text matches a name, the better place first.
enum _Match { nameStart, wordStart, insideWord }

/// Shortest typed text that may match inside a word ("milch" in
/// "Vollmilch"); shorter text matches there by chance ("mi" in "Yunmi").
const _insideWordMinLength = 3;

final _wordStart = RegExp(r'(^|[^\p{L}\p{N}])', unicode: true);

/// How [needle] matches [name], or null when it does not; an empty [needle]
/// matches every name at its start.
_Match? _matchOf(String name, String needle) {
  final lower = name.toLowerCase();
  if (lower.startsWith(needle)) return _Match.nameStart;
  for (final match in _wordStart.allMatches(lower)) {
    if (lower.startsWith(needle, match.end)) return _Match.wordStart;
  }
  return needle.length >= _insideWordMinLength && lower.contains(needle)
      ? _Match.insideWord
      : null;
}

/// Up to [limit] products of [catalog] on [shelf] that are not on the list
/// as still to buy, nor named in [shown]: more ideas from the same shelf.
List<ShoppingCatalogEntry> shoppingShelfIdeas(
  List<ShoppingCatalogEntry> catalog, {
  required ShoppingShelf shelf,
  required List<ShoppingListItem> items,
  Set<String> shown = const {},
  int limit = 6,
}) {
  final listed = {
    for (final item in items)
      if (item.isOpen) shoppingCatalogKey(item.name),
  };
  return [
    for (final entry in catalog)
      if (entry.shelf == shelf &&
          !listed.contains(shoppingCatalogKey(entry.name)) &&
          !shown.contains(shoppingCatalogKey(entry.name)))
        entry,
  ].take(limit).toList();
}
