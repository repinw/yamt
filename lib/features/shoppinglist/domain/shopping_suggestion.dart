/// A product proposed by a data-owning feature.
class ShoppingSuggestion {
  /// Creates a shopping suggestion without coupling to inventory models.
  const ShoppingSuggestion({
    required this.name,
    this.brand,
    this.purchaseCount = 0,
    this.isLowStock = false,
    this.isOutOfStock = false,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Distinct recorded purchases.
  final int purchaseCount;

  /// Whether remaining stock is low.
  final bool isLowStock;

  /// Whether no stock remains.
  final bool isOutOfStock;
}
