class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.normalizedBrand,
    required this.quantity,
    required this.estimatedUnitPrice,
    this.brand,
  });

  final String id;
  final String name;
  final String? brand;
  final String normalizedName;
  final String normalizedBrand;
  final int quantity;
  final double estimatedUnitPrice;

  double get estimatedTotal => estimatedUnitPrice * quantity;

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? normalizedName,
    String? normalizedBrand,
    int? quantity,
    double? estimatedUnitPrice,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      normalizedName: normalizedName ?? this.normalizedName,
      normalizedBrand: normalizedBrand ?? this.normalizedBrand,
      quantity: quantity ?? this.quantity,
      estimatedUnitPrice: estimatedUnitPrice ?? this.estimatedUnitPrice,
    );
  }
}
