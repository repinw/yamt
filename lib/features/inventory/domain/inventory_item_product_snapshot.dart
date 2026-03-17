import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

class InventoryItemProductSnapshot {
  const InventoryItemProductSnapshot({
    required this.name,
    this.brand,
    this.category,
    this.barcode,
    this.imageUrl,
    this.foodFingerprint,
    this.nutrition,
  });

  final String name;
  final String? brand;
  final String? category;
  final String? barcode;
  final String? imageUrl;
  final String? foodFingerprint;
  final GlobalFoodNutrition? nutrition;

  factory InventoryItemProductSnapshot.fromJson(Map<String, dynamic> json) {
    return InventoryItemProductSnapshot(
      name: json['name'] as String? ?? '',
      brand: _readTrimmedString(json['brand']),
      category: _readTrimmedString(json['category']),
      barcode: _readTrimmedString(json['barcode']),
      imageUrl: _readTrimmedString(json['image_url']),
      foodFingerprint: _readTrimmedString(json['food_fingerprint']),
      nutrition: _readNutrition(json['nutrition']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'brand': brand,
      'category': category,
      'barcode': barcode,
      'image_url': imageUrl,
      'food_fingerprint': foodFingerprint,
      'nutrition': nutrition?.toJson(),
    };
  }

  InventoryItemProductSnapshot copyWith({
    String? name,
    Object? brand = _keepValue,
    Object? category = _keepValue,
    Object? barcode = _keepValue,
    Object? imageUrl = _keepValue,
    Object? foodFingerprint = _keepValue,
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
      nutrition: nutrition == _keepValue
          ? this.nutrition
          : nutrition as GlobalFoodNutrition?,
    );
  }

  String get resolvedFoodFingerprint {
    final value = foodFingerprint?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return computeFoodFingerprint(name: name, brand: brand);
  }

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
