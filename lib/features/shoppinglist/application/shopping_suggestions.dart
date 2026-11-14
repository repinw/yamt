import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

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
