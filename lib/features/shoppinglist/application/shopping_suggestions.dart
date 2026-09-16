import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

/// Checks if a suggestion is already in the active shopping list.
bool isSuggestionAlreadyListed(
  List<ShoppingListItem> items,
  ShoppingSuggestion suggestion,
) => items.any(
  (item) =>
      !item.isArchived &&
      item.name.trim().toLowerCase() == suggestion.name.trim().toLowerCase() &&
      ((item.brand?.trim().isEmpty ?? true) ||
          item.brand?.trim().toLowerCase() ==
              suggestion.brand?.trim().toLowerCase()),
);
