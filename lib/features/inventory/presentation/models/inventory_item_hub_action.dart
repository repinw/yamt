/// Actions of the item hub: the lines of its item card, and its trash
/// button.
enum InventoryItemHubAction {
  /// Put the item on the shopping list.
  addToShoppingList,

  /// Edit the stock item.
  edit,

  /// Swap the item's catalog product.
  replace,

  /// Discard, consume elsewhere, or delete the item. The trash button runs
  /// it; the item card has no line for it.
  remove,
}
