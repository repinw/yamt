import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Defines inventory item product snapshot.
@immutable
class InventoryItemProductSnapshot {
  /// The inventory item product snapshot.
  const InventoryItemProductSnapshot({
    required this.name,
    this.brand,
    this.category,
    this.barcode,
    this.imageUrl,
    this.foodFingerprint,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
  });

  /// Creates a [InventoryItemProductSnapshot] for from json.
  factory InventoryItemProductSnapshot.fromJson(Map<String, dynamic> json) {
    return InventoryItemProductSnapshot(
      name: json['name'] as String? ?? '',
      brand: _readTrimmedString(json['brand']),
      category: _readTrimmedString(json['category']),
      barcode: _readTrimmedString(json['barcode']),
      imageUrl: _readTrimmedString(json['image_url']),
      foodFingerprint: _readTrimmedString(json['food_fingerprint']),
      servingSize:
          _readTrimmedString(json['serving_size']) ??
          _readTrimmedString(json['servingSize']),
      servingQuantity: _readDouble(
        json['serving_quantity'] ?? json['servingQuantity'],
      ),
      servingQuantityUnit: _readTrimmedString(
        json['serving_quantity_unit'] ?? json['servingQuantityUnit'],
      ),
      nutrition: _readNutrition(json['nutrition']),
    );
  }

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The category.
  final String? category;

  /// The barcode.
  final String? barcode;

  /// The image url.
  final String? imageUrl;

  /// The food fingerprint.
  final String? foodFingerprint;

  /// The serving size.
  final String? servingSize;

  /// The serving quantity.
  final double? servingQuantity;

  /// The serving quantity unit.
  final String? servingQuantityUnit;

  /// The nutrition.
  final GlobalFoodNutrition? nutrition;

  /// To json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'brand': brand,
      'category': category,
      'barcode': barcode,
      'image_url': imageUrl,
      'food_fingerprint': foodFingerprint,
      'serving_size': servingSize,
      'serving_quantity': servingQuantity,
      'serving_quantity_unit': servingQuantityUnit,
      'nutrition': nutrition?.toJson(),
    };
  }

  /// Copy with.
  InventoryItemProductSnapshot copyWith({
    String? name,
    Object? brand = _keepValue,
    Object? category = _keepValue,
    Object? barcode = _keepValue,
    Object? imageUrl = _keepValue,
    Object? foodFingerprint = _keepValue,
    Object? servingSize = _keepValue,
    Object? servingQuantity = _keepValue,
    Object? servingQuantityUnit = _keepValue,
    Object? nutrition = _keepValue,
  }) {
    return InventoryItemProductSnapshot(
      name: name ?? this.name,
      brand: brand == _keepValue ? this.brand : brand as String?,
      category: category == _keepValue ? this.category : category as String?,
      barcode: barcode == _keepValue ? this.barcode : barcode as String?,
      imageUrl: imageUrl == _keepValue ? this.imageUrl : imageUrl as String?,
      foodFingerprint: foodFingerprint == _keepValue
          ? this.foodFingerprint
          : foodFingerprint as String?,
      servingSize: servingSize == _keepValue
          ? this.servingSize
          : servingSize as String?,
      servingQuantity: servingQuantity == _keepValue
          ? this.servingQuantity
          : _readDouble(servingQuantity),
      servingQuantityUnit: servingQuantityUnit == _keepValue
          ? this.servingQuantityUnit
          : servingQuantityUnit as String?,
      nutrition: nutrition == _keepValue
          ? this.nutrition
          : nutrition as GlobalFoodNutrition?,
    );
  }

  /// The resolved food fingerprint.
  String get resolvedFoodFingerprint {
    final value = foodFingerprint?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return computeFoodFingerprint(name: name, brand: brand);
  }

  /// The normalized barcode.
  String? get normalizedBarcode {
    final value = barcode?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryItemProductSnapshot &&
            other.name == name &&
            other.brand == brand &&
            other.category == category &&
            other.barcode == barcode &&
            other.imageUrl == imageUrl &&
            other.foodFingerprint == foodFingerprint &&
            other.servingSize == servingSize &&
            other.servingQuantity == servingQuantity &&
            other.servingQuantityUnit == servingQuantityUnit &&
            other.nutrition == nutrition;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      brand,
      category,
      barcode,
      imageUrl,
      foodFingerprint,
      servingSize,
      servingQuantity,
      servingQuantityUnit,
      nutrition,
    );
  }
}

String? _readTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

double? _readDouble(Object? value) {
  if (value is num) {
    final parsed = value.toDouble();
    return parsed > 0 ? parsed : null;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
  return null;
}

GlobalFoodNutrition? _readNutrition(Object? value) {
  if (value is Map<String, dynamic>) {
    return GlobalFoodNutrition.fromJson(value);
  }
  if (value is Map) {
    return GlobalFoodNutrition.fromJson(
      value.map(
        (key, nestedValue) =>
            MapEntry<String, dynamic>(key.toString(), nestedValue),
      ),
    );
  }
  return null;
}

const Object _keepValue = Object();
