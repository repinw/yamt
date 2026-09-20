/// Defines inventory calorie entry commit result.
class InventoryCalorieEntryCommitResult {
  /// The inventory calorie entry commit result.
  const new({
    required this.itemId,
    required this.quantity,
    required this.currentAmount,
  });

  /// The item id.
  final String itemId;

  /// The quantity.
  final int quantity;

  /// The current amount.
  final int currentAmount;
}
