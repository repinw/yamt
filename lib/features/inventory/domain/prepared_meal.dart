import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class PreparedMeal {
  const PreparedMeal({
    required this.id,
    required this.name,
    this.imageBase64,
    required this.totalPortions,
    required this.remainingPortions,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.createdAt,
    required this.updatedAt,
    required this.components,
  });

  factory PreparedMeal.fromJson(Map<String, dynamic> json) {
    return PreparedMeal(
      id: _readTrimmedString(json['id']) ?? '',
      name: _readTrimmedString(json['name']) ?? '',
      imageBase64: _readTrimmedString(json['image_base64']),
      totalPortions: _readInt(json['total_portions']) ?? 0,
      remainingPortions: _readInt(json['remaining_portions']) ?? 0,
      totalKcal: _readDouble(json['total_kcal']) ?? 0,
      totalProtein: _readDouble(json['total_protein']) ?? 0,
      totalCarbs: _readDouble(json['total_carbs']) ?? 0,
      totalFat: _readDouble(json['total_fat']) ?? 0,
      createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _readDateTime(json['updated_at']) ?? DateTime.now(),
      components: _readComponents(json['components']),
    );
  }

  final String id;
  final String name;
  final String? imageBase64;
  final int totalPortions;
  final int remainingPortions;
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PreparedMealComponent> components;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'image_base64': imageBase64,
      'total_portions': totalPortions,
      'remaining_portions': remainingPortions,
      'total_kcal': totalKcal,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'components': components.map((component) => component.toJson()).toList(),
    };
  }

  PreparedMeal copyWith({
    String? id,
    String? name,
    Object? imageBase64 = _keepValue,
    int? totalPortions,
    int? remainingPortions,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PreparedMealComponent>? components,
  }) {
    return PreparedMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      imageBase64: imageBase64 == _keepValue
          ? this.imageBase64
          : imageBase64 as String?,
      totalPortions: totalPortions ?? this.totalPortions,
      remainingPortions: remainingPortions ?? this.remainingPortions,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      components: components ?? this.components,
    );
  }

  bool get isDepleted => remainingPortions <= 0;

  Uint8List? get imageBytes {
    final raw = imageBase64;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  double get remainingRatio {
    if (totalPortions <= 0) {
      return 0;
    }
    return remainingPortions / totalPortions;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreparedMeal &&
            other.id == id &&
            other.name == name &&
            other.imageBase64 == imageBase64 &&
            other.totalPortions == totalPortions &&
            other.remainingPortions == remainingPortions &&
            other.totalKcal == totalKcal &&
            other.totalProtein == totalProtein &&
            other.totalCarbs == totalCarbs &&
            other.totalFat == totalFat &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            const ListEquality<PreparedMealComponent>().equals(
              other.components,
              components,
            );
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      id,
      name,
      imageBase64,
      totalPortions,
      remainingPortions,
      totalKcal,
      totalProtein,
      totalCarbs,
      totalFat,
      createdAt,
      updatedAt,
      const ListEquality<PreparedMealComponent>().hash(components),
    ]);
  }
}

class PreparedMealComponent {
  const PreparedMealComponent({
    required this.inventoryItemId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.usedAmount,
    required this.usedUnit,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.sourceItemSnapshot,
  });

  factory PreparedMealComponent.fromJson(Map<String, dynamic> json) {
    return PreparedMealComponent(
      inventoryItemId: _readTrimmedString(json['inventory_item_id']) ?? '',
      name: _readTrimmedString(json['name']) ?? '',
      brand: _readTrimmedString(json['brand']),
      imageUrl: _readTrimmedString(json['image_url']),
      usedAmount: _readInt(json['used_amount']) ?? 0,
      usedUnit: _readAmountUnit(json['used_unit']) ?? InventoryAmountUnit.piece,
      totalKcal: _readDouble(json['total_kcal']) ?? 0,
      totalProtein: _readDouble(json['total_protein']) ?? 0,
      totalCarbs: _readDouble(json['total_carbs']) ?? 0,
      totalFat: _readDouble(json['total_fat']) ?? 0,
      sourceItemSnapshot: InventoryItem.fromJson(
        _readMap(json['source_item_snapshot']),
      ),
    );
  }

  final String inventoryItemId;
  final String name;
  final String? brand;
  final String? imageUrl;
  final int usedAmount;
  final InventoryAmountUnit usedUnit;
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final InventoryItem sourceItemSnapshot;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inventory_item_id': inventoryItemId,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'used_amount': usedAmount,
      'used_unit': _amountUnitCode(usedUnit),
      'total_kcal': totalKcal,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'source_item_snapshot': sourceItemSnapshot.toJson(),
    };
  }

  PreparedMealComponent copyWith({
    String? inventoryItemId,
    String? name,
    Object? brand = _keepValue,
    Object? imageUrl = _keepValue,
    int? usedAmount,
    InventoryAmountUnit? usedUnit,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    InventoryItem? sourceItemSnapshot,
  }) {
    return PreparedMealComponent(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      name: name ?? this.name,
      brand: brand == _keepValue ? this.brand : brand as String?,
      imageUrl: imageUrl == _keepValue ? this.imageUrl : imageUrl as String?,
      usedAmount: usedAmount ?? this.usedAmount,
      usedUnit: usedUnit ?? this.usedUnit,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      sourceItemSnapshot: sourceItemSnapshot ?? this.sourceItemSnapshot,
    );
  }

  GlobalFoodNutrition get sourceNutrition {
    return sourceItemSnapshot.nutrition ??
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.missing,
        );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreparedMealComponent &&
            other.inventoryItemId == inventoryItemId &&
            other.name == name &&
            other.brand == brand &&
            other.imageUrl == imageUrl &&
            other.usedAmount == usedAmount &&
            other.usedUnit == usedUnit &&
            other.totalKcal == totalKcal &&
            other.totalProtein == totalProtein &&
            other.totalCarbs == totalCarbs &&
            other.totalFat == totalFat &&
            other.sourceItemSnapshot == sourceItemSnapshot;
  }

  @override
  int get hashCode {
    return Object.hash(
      inventoryItemId,
      name,
      brand,
      imageUrl,
      usedAmount,
      usedUnit,
      totalKcal,
      totalProtein,
      totalCarbs,
      totalFat,
      sourceItemSnapshot,
    );
  }
}

List<PreparedMealComponent> _readComponents(Object? value) {
  if (value is! List) {
    return const <PreparedMealComponent>[];
  }
  return value
      .whereType<Map>()
      .map(
        (entry) => PreparedMealComponent.fromJson(
          entry.map(
            (key, nestedValue) =>
                MapEntry<String, dynamic>(key.toString(), nestedValue),
          ),
        ),
      )
      .toList(growable: false);
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry<String, dynamic>(key.toString(), nestedValue),
    );
  }
  return const <String, dynamic>{};
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

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

String? _readTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

InventoryAmountUnit? _readAmountUnit(Object? value) {
  final raw = value is String ? value.trim() : '';
  for (final unit in InventoryAmountUnit.values) {
    if (_amountUnitCode(unit) == raw) {
      return unit;
    }
  }
  return null;
}

const Object _keepValue = Object();

String _amountUnitCode(InventoryAmountUnit unit) {
  return switch (unit) {
    InventoryAmountUnit.gram => 'g',
    InventoryAmountUnit.milliliter => 'ml',
    InventoryAmountUnit.piece => 'pc',
  };
}
