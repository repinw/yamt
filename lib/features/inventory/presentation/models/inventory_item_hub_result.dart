import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// Actions of the item card on the item hub.
enum InventoryItemHubAction {
  /// Put the item on the shopping list.
  addToShoppingList,

  /// Edit the stock item.
  edit,

  /// Swap the item's catalog product.
  replace,

  /// Discard, consume elsewhere, or delete the item.
  remove,
}

/// What the user chose on the item hub.
sealed class InventoryItemHubResult {
  const new();
}

/// The user logged an amount of the item.
@immutable
final class InventoryItemHubEat extends InventoryItemHubResult {
  /// Creates the eat result.
  const new(this.request);

  /// The entered amount and log time.
  final InventoryItemEatRequest request;
}

/// The user picked an action from the item card.
@immutable
final class InventoryItemHubPick extends InventoryItemHubResult {
  /// Creates the pick result.
  const new(this.action);

  /// The picked action.
  final InventoryItemHubAction action;
}
