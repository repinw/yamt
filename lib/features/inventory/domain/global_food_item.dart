import 'package:collection/collection.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/domain/food_fingerprint.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';

enum GlobalFoodItemStatus { active, candidate, merged }

class GlobalFoodItem {
  const GlobalFoodItem({
    required this.id,
    required this.foodFingerprint,
    required this.name,
    required this.normalizedName,
    required this.searchTokens,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.category,
    this.storeName,
    this.barcode,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
    this.normalizedBrand,
    this.normalizedStoreName,
    this.mergedIntoId,
  });

  factory GlobalFoodItem.create({
    required String id,
    required String name,
    required DateTime now,
    String? brand,
    String? category,
    String? storeName,
    String? barcode,
    String? imageUrl,
    String? packageWeight,
    String? servingSize,
    double? servingQuantity,
    String? servingQuantityUnit,
    String? foodFingerprint,
    GlobalFoodNutrition? nutrition,
    GlobalFoodItemStatus status = GlobalFoodItemStatus.active,
  }) {
    final normalizedStoreName = _normalizedStoreNameValue(storeName);
    return GlobalFoodItem(
      id: id,
      foodFingerprint:
          _normalizeOptional(foodFingerprint) ??
          computeFoodFingerprint(name: name, brand: brand),
      name: name.trim(),
      normalizedName: normalizeGlobalFoodText(name),
      searchTokens: buildGlobalFoodSearchTokens(
        name: name,
        brand: brand,
        category: category,
      ),
      status: status,
      createdAt: now,
      updatedAt: now,
      brand: _normalizeOptional(brand),
      category: _normalizeOptional(category),
      storeName: normalizedStoreName,
      barcode: _normalizeOptional(barcode),
      imageUrl: _normalizeOptional(imageUrl),
      packageWeight: _normalizeOptional(packageWeight),
      servingSize: _normalizeOptional(servingSize),
      servingQuantity: _normalizeServingQuantity(servingQuantity),
      servingQuantityUnit: _normalizeOptional(servingQuantityUnit),
      nutrition: nutrition,
      normalizedBrand: normalizeGlobalFoodText(brand ?? ''),
      normalizedStoreName: _normalizeOptionalLookupText(normalizedStoreName),
    );
  }

  factory GlobalFoodItem.fromJson(Map<String, dynamic> json) {
    final storeName = _normalizedStoreNameValue(json['store_name']);
    return GlobalFoodItem(
      id: json['id'] as String? ?? '',
      foodFingerprint:
          _normalizeOptional(json['food_fingerprint']) ??
          computeFoodFingerprint(
            name: json['name'] as String? ?? '',
            brand: _normalizeOptional(json['brand']),
          ),
      name: json['name'] as String? ?? '',
      normalizedName:
          _normalizeOptional(json['normalized_name']) ??
          normalizeGlobalFoodText(json['name'] as String? ?? ''),
      searchTokens: _readStringList(json['search_tokens']),
      status: _statusFromJson(json['status']),
      createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _readDateTime(json['updated_at']) ?? DateTime.now(),
      brand: _normalizeOptional(json['brand']),
      category: _normalizeOptional(json['category']),
      storeName: storeName,
      barcode: _normalizeOptional(json['barcode']),
      imageUrl: _normalizeOptional(json['image_url']),
      packageWeight:
          _normalizeOptional(json['package_weight']) ??
          _normalizeOptional(json['weight']),
      servingSize:
          _normalizeOptional(json['serving_size']) ??
          _normalizeOptional(json['servingSize']),
      servingQuantity: _readDouble(
        json['serving_quantity'] ?? json['servingQuantity'],
      ),
      servingQuantityUnit: _normalizeOptional(
        json['serving_quantity_unit'] ?? json['servingQuantityUnit'],
      ),
      nutrition: _readNutrition(json['nutrition']),
      normalizedBrand:
          _normalizeOptional(json['normalized_brand']) ??
          normalizeGlobalFoodText(_normalizeOptional(json['brand']) ?? ''),
      normalizedStoreName:
          _normalizeOptional(json['normalized_store_name']) ??
          _normalizeOptionalLookupText(storeName),
      mergedIntoId: _normalizeOptional(json['merged_into_id']),
    );
  }

  final String id;
  final String foodFingerprint;
  final String name;
  final String? brand;
  final String? category;
  final String? storeName;
  final String? barcode;
  final String? imageUrl;
  final String? packageWeight;
  final String? servingSize;
  final double? servingQuantity;
  final String? servingQuantityUnit;
  final GlobalFoodNutrition? nutrition;
  final String normalizedName;
  final String? normalizedBrand;
  final String? normalizedStoreName;
  final List<String> searchTokens;
  final GlobalFoodItemStatus status;
  final String? mergedIntoId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'food_fingerprint': foodFingerprint,
      'name': name,
      'brand': brand,
      'category': category,
      'store_name': storeName,
      'barcode': barcode,
      'image_url': imageUrl,
      'package_weight': packageWeight,
      'serving_size': servingSize,
      'serving_quantity': servingQuantity,
      'serving_quantity_unit': servingQuantityUnit,
      'nutrition': nutrition?.toJson(),
      'normalized_name': normalizedName,
      'normalized_brand': normalizedBrand,
      'normalized_store_name': normalizedStoreName,
      'search_tokens': searchTokens,
      'status': status.name,
      'merged_into_id': mergedIntoId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalFoodItem copyWith({
    String? id,
    String? foodFingerprint,
    String? name,
    Object? brand = _keepValue,
    Object? category = _keepValue,
    Object? storeName = _keepValue,
    Object? barcode = _keepValue,
    Object? imageUrl = _keepValue,
    Object? packageWeight = _keepValue,
    Object? servingSize = _keepValue,
    Object? servingQuantity = _keepValue,
    Object? servingQuantityUnit = _keepValue,
    Object? nutrition = _keepValue,
    String? normalizedName,
    Object? normalizedBrand = _keepValue,
    Object? normalizedStoreName = _keepValue,
    List<String>? searchTokens,
    GlobalFoodItemStatus? status,
    Object? mergedIntoId = _keepValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalFoodItem(
      id: id ?? this.id,
      foodFingerprint: foodFingerprint ?? this.foodFingerprint,
      name: name ?? this.name,
      brand: brand == _keepValue ? this.brand : brand as String?,
      category: category == _keepValue ? this.category : category as String?,
      storeName: storeName == _keepValue
          ? this.storeName
          : storeName as String?,
      barcode: barcode == _keepValue ? this.barcode : barcode as String?,
      imageUrl: imageUrl == _keepValue ? this.imageUrl : imageUrl as String?,
      packageWeight: packageWeight == _keepValue
          ? this.packageWeight
          : packageWeight as String?,
      servingSize: servingSize == _keepValue
          ? this.servingSize
          : servingSize as String?,
      servingQuantity: servingQuantity == _keepValue
          ? this.servingQuantity
          : _normalizeServingQuantity(servingQuantity),
      servingQuantityUnit: servingQuantityUnit == _keepValue
          ? this.servingQuantityUnit
          : servingQuantityUnit as String?,
      nutrition: nutrition == _keepValue
          ? this.nutrition
          : nutrition as GlobalFoodNutrition?,
      normalizedName: normalizedName ?? this.normalizedName,
      normalizedBrand: normalizedBrand == _keepValue
          ? this.normalizedBrand
          : normalizedBrand as String?,
      normalizedStoreName: normalizedStoreName == _keepValue
          ? this.normalizedStoreName
          : normalizedStoreName as String?,
      searchTokens: searchTokens ?? this.searchTokens,
      status: status ?? this.status,
      mergedIntoId: mergedIntoId == _keepValue
          ? this.mergedIntoId
          : mergedIntoId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get resolvedFoodFingerprint {
    final value = foodFingerprint.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return computeFoodFingerprint(name: name, brand: brand);
  }

  String? get normalizedBarcode => _normalizeOptional(barcode);

  InventoryItemProductSnapshot toProductSnapshot() {
    return InventoryItemProductSnapshot(
      name: name,
      brand: brand,
      category: category,
      barcode: barcode,
      imageUrl: imageUrl,
      foodFingerprint: resolvedFoodFingerprint,
      servingSize: servingSize,
      servingQuantity: servingQuantity,
      servingQuantityUnit: servingQuantityUnit,
      nutrition: nutrition,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalFoodItem &&
            other.id == id &&
            other.foodFingerprint == foodFingerprint &&
            other.name == name &&
            other.brand == brand &&
            other.category == category &&
            other.storeName == storeName &&
            other.barcode == barcode &&
            other.imageUrl == imageUrl &&
            other.packageWeight == packageWeight &&
            other.servingSize == servingSize &&
            other.servingQuantity == servingQuantity &&
            other.servingQuantityUnit == servingQuantityUnit &&
            other.nutrition == nutrition &&
            other.normalizedName == normalizedName &&
            other.normalizedBrand == normalizedBrand &&
            other.normalizedStoreName == normalizedStoreName &&
            const ListEquality<String>().equals(
              other.searchTokens,
              searchTokens,
            ) &&
            other.status == status &&
            other.mergedIntoId == mergedIntoId &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      foodFingerprint,
      name,
      brand,
      category,
      storeName,
      barcode,
      imageUrl,
      packageWeight,
      servingSize,
      servingQuantity,
      servingQuantityUnit,
      nutrition,
      normalizedName,
      normalizedBrand,
      normalizedStoreName,
      const ListEquality<String>().hash(searchTokens),
      status,
      mergedIntoId,
      createdAt,
      updatedAt,
    );
  }
}

String normalizeGlobalFoodText(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }
  return lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> buildGlobalFoodSearchTokens({
  required String name,
  String? brand,
  String? category,
}) {
  final normalized = <String>[
    normalizeGlobalFoodText(name),
    normalizeGlobalFoodText(brand ?? ''),
    normalizeGlobalFoodText(category ?? ''),
  ];
  final tokens = <String>{};
  for (final value in normalized) {
    if (value.isEmpty) {
      continue;
    }
    tokens.add(value);
    tokens.addAll(
      value
          .split(' ')
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty),
    );
  }
  return tokens.toList(growable: false);
}

String? _normalizeOptional(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _normalizedStoreNameValue(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = normalizeStoreName(value);
  return _normalizeOptional(normalized);
}

String? _normalizeOptionalLookupText(Object? value) {
  final normalized = normalizeGlobalFoodText(value is String ? value : '');
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}

double? _normalizeServingQuantity(Object? value) {
  final parsed = _readDouble(value);
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim());
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

GlobalFoodItemStatus _statusFromJson(Object? value) {
  final raw = value is String ? value.trim() : '';
  return GlobalFoodItemStatus.values.firstWhereOrNull(
        (status) => status.name == raw,
      ) ??
      GlobalFoodItemStatus.active;
}

const Object _keepValue = Object();
