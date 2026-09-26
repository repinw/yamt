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
