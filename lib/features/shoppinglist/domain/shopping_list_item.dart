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
    this.isFavorite = false,
    this.isArchived = false,
    this.repeatEveryDays = 0,
    this.repeatQuantity = 1,
    this.nextDueDate,
  });

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
      isFavorite: json['is_favorite'] == true,
      isArchived: json['is_archived'] == true,
      repeatEveryDays: (json['repeat_every_days'] as num?)?.toInt() ?? 0,
      repeatQuantity: (json['repeat_quantity'] as num?)?.toInt() ?? 1,
      nextDueDate: DateTime.tryParse(json['next_due_date']?.toString() ?? ''),
    );
  }

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

  /// Keep as a reusable favorite after removing it from the list.
  final bool isFavorite;

  /// Saved product currently outside the shopping list.
  final bool isArchived;

  /// Calendar-day recurrence interval; zero disables recurrence.
  final int repeatEveryDays;

  /// Quantity restored by the next recurrence.
  final int repeatQuantity;

  /// Next scheduled local calendar date.
  final DateTime? nextDueDate;

  /// Whether removing the list entry must retain its saved settings.
  bool get isSaved => isFavorite || repeatEveryDays > 0;

  /// The estimated total.
  double get estimatedTotal => estimatedUnitPrice * quantity;

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
      'is_favorite': isFavorite,
      'is_archived': isArchived,
      'repeat_every_days': repeatEveryDays,
      'repeat_quantity': repeatQuantity,
      'next_due_date': nextDueDate?.toIso8601String(),
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
    bool? isFavorite,
    bool? isArchived,
    int? repeatEveryDays,
    int? repeatQuantity,
    DateTime? nextDueDate,
    bool clearNextDueDate = false,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      normalizedName: normalizedName ?? this.normalizedName,
      normalizedBrand: normalizedBrand ?? this.normalizedBrand,
      quantity: quantity ?? this.quantity,
      estimatedUnitPrice: estimatedUnitPrice ?? this.estimatedUnitPrice,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      repeatQuantity: repeatQuantity ?? this.repeatQuantity,
      nextDueDate: clearNextDueDate ? null : nextDueDate ?? this.nextDueDate,
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
