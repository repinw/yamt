import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

/// Identifies a product by [name] and [brand], whatever their spelling.
String shoppingProductKey(String name, String? brand) =>
    '${name.trim().toLowerCase()}|${brand?.trim().toLowerCase() ?? ''}';

/// Identifies the product of a suggestion, whatever its spelling.
String shoppingSuggestionKey(ShoppingSuggestion suggestion) =>
    shoppingProductKey(suggestion.name, suggestion.brand);

/// Puts the suggestions the user pushed back behind all others, the one
/// pushed back longest ago first, so every suggestion gets its turn.
/// [pushedBack] holds suggestion keys in the order they were pushed back.
List<ShoppingSuggestion> queueShoppingSuggestions(
  List<ShoppingSuggestion> suggestions,
  List<String> pushedBack,
) {
  final turn = {for (final (index, key) in pushedBack.indexed) key: index};
  final front = <ShoppingSuggestion>[];
  final back = <ShoppingSuggestion>[];
  for (final suggestion in suggestions) {
    (turn.containsKey(shoppingSuggestionKey(suggestion)) ? back : front).add(
      suggestion,
    );
  }
  back.sort(
    (a, b) => turn[shoppingSuggestionKey(a)]!.compareTo(
      turn[shoppingSuggestionKey(b)]!,
    ),
  );
  return [...front, ...back];
}

/// Moves [suggestion] to the end of [pushedBack] and forgets the keys that
/// [current] no longer suggests.
List<String> pushShoppingSuggestionBack(
  List<String> pushedBack,
  ShoppingSuggestion suggestion, {
  required List<ShoppingSuggestion> current,
}) {
  final key = shoppingSuggestionKey(suggestion);
  final suggested = {for (final other in current) shoppingSuggestionKey(other)};
  return [
    for (final other in pushedBack)
      if (other != key && suggested.contains(other)) other,
    key,
  ];
}
