/// What the user picked on the page that puts a new product into the
/// Vorrat.
sealed class InventoryStockAddResult {
  const new();
}

/// Put [packages] packages of the product into the Vorrat.
final class InventoryStockAddConfirmed extends InventoryStockAddResult {
  /// Creates the result.
  const new(this.packages);

  /// Number of packages, at least one.
  final int packages;
}

/// Open the product editor, then come back to the page with [packages].
final class InventoryStockAddEdit extends InventoryStockAddResult {
  /// Creates the result.
  const new(this.packages);

  /// Number of packages picked so far.
  final int packages;
}
