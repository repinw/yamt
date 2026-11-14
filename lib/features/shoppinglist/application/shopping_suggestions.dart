import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
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

/// The suggestions to show: without the products that are still to buy on
/// the list [scope] shows, the ones in [pushedBack] behind all others.
List<ShoppingSuggestion> visibleShoppingSuggestions(
  List<ShoppingSuggestion> suggestions, {
  required List<ShoppingListItem> items,
  required ShoppingListScope scope,
  required List<String> pushedBack,
}) {
  final shown = [
    for (final item in items)
      if (scope.shows(item)) item,
  ];
  return queueShoppingSuggestions([
    for (final suggestion in suggestions)
      if (!isSuggestionAlreadyListed(shown, suggestion)) suggestion,
  ], pushedBack);
}

/// The suggestions with what the plans need in front: one suggestion per
/// food, for its first planned meal, the stock reasons of the same food kept.
/// [groups] come in plan order.
List<ShoppingSuggestion> shoppingSuggestionsWithPlan(
  List<ShoppingPlanNeedGroup> groups,
  List<ShoppingSuggestion> suggestions,
) {
  final stock = {
    for (final suggestion in suggestions)
      shoppingSuggestionKey(suggestion): suggestion,
  };
  final planned = <String, ShoppingSuggestion>{};
  for (final group in groups) {
    for (final need in group.needs) {
      final key = shoppingProductKey(need.name, need.brand);
      if (planned.containsKey(key)) continue;
      final known = stock[key];
      planned[key] = ShoppingSuggestion(
        name: need.name,
        brand: need.brand,
        purchaseCount: known?.purchaseCount ?? 0,
        isLowStock: known?.isLowStock ?? false,
        isOutOfStock: known?.isOutOfStock ?? false,
        plannedFor: (day: group.day, mealType: group.mealType),
      );
    }
  }
  return [
    ...planned.values,
    for (final suggestion in suggestions)
      if (!planned.containsKey(shoppingSuggestionKey(suggestion))) suggestion,
  ];
}
