/// Normalizes receipt quantities for savable and review-only items.
({int quantity, int initialQuantity}) normalizeReceiptItemQuantities({
  required int quantity,
  required bool canBeSavedToInventory,
}) {
  if (canBeSavedToInventory) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    return (quantity: safeQuantity, initialQuantity: safeQuantity);
  }

  final safeQuantity = quantity < 0 ? 0 : quantity;
  return (quantity: safeQuantity, initialQuantity: safeQuantity);
}
