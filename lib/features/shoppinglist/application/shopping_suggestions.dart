import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion_queue.dart';

/// Checks if a suggestion is on the list and still to buy.
bool isSuggestionAlreadyListed(
  List<ShoppingListItem> items,
  ShoppingSuggestion suggestion,
) => items.any(
  (item) =>
      item.isOpen &&
      item.name.trim().toLowerCase() == suggestion.name.trim().toLowerCase() &&
      ((item.brand?.trim().isEmpty ?? true) ||
          item.brand?.trim().toLowerCase() ==
              suggestion.brand?.trim().toLowerCase()),
);

/// The suggestions to show: without the products that are on the list and
/// still to buy, the ones in [pushedBack] behind all others.
List<ShoppingSuggestion> visibleShoppingSuggestions(
  List<ShoppingSuggestion> suggestions, {
  required List<ShoppingListItem> items,
  required List<String> pushedBack,
}) => queueShoppingSuggestions([
  for (final suggestion in suggestions)
    if (!isSuggestionAlreadyListed(items, suggestion)) suggestion,
], pushedBack);
