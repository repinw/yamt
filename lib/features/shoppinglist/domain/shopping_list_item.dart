/// Defines shopping list item.
class ShoppingListItem {
  /// The shopping list item.
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.normalizedBrand,
    required this.quantity,
    required this.estimatedUnitPrice,
    this.brand,
  });

  /// The id.
  final String id;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The normalized name.
  final String normalizedName;

  /// The normalized brand.
  final String normalizedBrand;

  /// The quantity.
  final int quantity;

  /// The estimated unit price.
  final double estimatedUnitPrice;

  /// The estimated total.
  double get estimatedTotal => estimatedUnitPrice * quantity;

  /// Creates a [ShoppingListItem] for from json.
  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      brand: _nullableStringValue(json['brand']),
      normalizedName: _stringValue(json['normalized_name']),
      normalizedBrand: _stringValue(json['normalized_brand']),
      quantity: _intValue(json['quantity']),
      estimatedUnitPrice: _doubleValue(json['estimated_unit_price']),
    );
  }

  /// To json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'brand': brand,
      'normalized_name': normalizedName,
      'normalized_brand': normalizedBrand,
      'quantity': quantity,
      'estimated_unit_price': estimatedUnitPrice,
    };
  }

  /// Copy with.
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

  static String _stringValue(Object? value) {
    if (value is String) {
      return value;
    }
    throw FormatException('Expected a string but got: $value');
  }

  static String? _nullableStringValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('Expected a nullable string but got: $value');
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Expected an int but got: $value');
  }

  static double _doubleValue(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('Expected a double but got: $value');
  }
}
