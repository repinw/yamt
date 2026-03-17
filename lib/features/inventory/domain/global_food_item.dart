import 'package:collection/collection.dart';
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
    this.barcode,
    this.imageUrl,
    this.nutrition,
    this.normalizedBrand,
    this.mergedIntoId,
  });

  factory GlobalFoodItem.create({
    required String id,
    required String name,
    required DateTime now,
    String? brand,
    String? category,
    String? barcode,
    String? imageUrl,
    String? foodFingerprint,
    GlobalFoodNutrition? nutrition,
    GlobalFoodItemStatus status = GlobalFoodItemStatus.active,
  }) {
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
      barcode: _normalizeOptional(barcode),
      imageUrl: _normalizeOptional(imageUrl),
      nutrition: nutrition,
      normalizedBrand: normalizeGlobalFoodText(brand ?? ''),
    );
  }

  factory GlobalFoodItem.fromJson(Map<String, dynamic> json) {
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
      barcode: _normalizeOptional(json['barcode']),
      imageUrl: _normalizeOptional(json['image_url']),
      nutrition: _readNutrition(json['nutrition']),
      normalizedBrand:
          _normalizeOptional(json['normalized_brand']) ??
          normalizeGlobalFoodText(_normalizeOptional(json['brand']) ?? ''),
      mergedIntoId: _normalizeOptional(json['merged_into_id']),
    );
  }

  final String id;
  final String foodFingerprint;
  final String name;
  final String? brand;
  final String? category;
  final String? barcode;
  final String? imageUrl;
  final GlobalFoodNutrition? nutrition;
  final String normalizedName;
  final String? normalizedBrand;
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
      'barcode': barcode,
      'image_url': imageUrl,
      'nutrition': nutrition?.toJson(),
      'normalized_name': normalizedName,
      'normalized_brand': normalizedBrand,
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
    Object? barcode = _keepValue,
    Object? imageUrl = _keepValue,
    Object? nutrition = _keepValue,
    String? normalizedName,
    Object? normalizedBrand = _keepValue,
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
      barcode: barcode == _keepValue ? this.barcode : barcode as String?,
      imageUrl: imageUrl == _keepValue ? this.imageUrl : imageUrl as String?,
      nutrition: nutrition == _keepValue
          ? this.nutrition
          : nutrition as GlobalFoodNutrition?,
      normalizedName: normalizedName ?? this.normalizedName,
      normalizedBrand: normalizedBrand == _keepValue
          ? this.normalizedBrand
          : normalizedBrand as String?,
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
            other.barcode == barcode &&
            other.imageUrl == imageUrl &&
            other.nutrition == nutrition &&
            other.normalizedName == normalizedName &&
            other.normalizedBrand == normalizedBrand &&
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
      barcode,
      imageUrl,
      nutrition,
      normalizedName,
      normalizedBrand,
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
