import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'prepared_meal.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PreparedMeal {
  const PreparedMeal({
    required this.id,
    required this.name,
    this.imageAssetId,
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

  factory PreparedMeal.fromJson(Map<String, dynamic> json) =>
      _$PreparedMealFromJson(json);

  @JsonKey(fromJson: _readRequiredString)
  final String id;
  @JsonKey(fromJson: _readRequiredString)
  final String name;
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageAssetId;
  @JsonKey(fromJson: _readIntOrZero)
  final int totalPortions;
  @JsonKey(fromJson: _readIntOrZero)
  final int remainingPortions;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalKcal;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalProtein;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalCarbs;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalFat;
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime createdAt;
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime updatedAt;
  @JsonKey(defaultValue: <PreparedMealComponent>[])
  final List<PreparedMealComponent> components;

  Map<String, dynamic> toJson() => _$PreparedMealToJson(this);

  PreparedMeal copyWith({
    String? id,
    String? name,
    Object? imageAssetId = _keepValue,
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
      imageAssetId: imageAssetId == _keepValue
          ? this.imageAssetId
          : imageAssetId as String?,
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

  double get remainingRatio {
    if (totalPortions <= 0) {
      return 0;
    }
    return remainingPortions / totalPortions;
  }

  /// Sum of all component costs based on the source inventory snapshots.
  double get totalPrice {
    return components.fold<double>(
      0,
      (sum, component) => sum + component.totalPrice,
    );
  }

  /// Shared amount basis for a 100 g/ml view when all components align.
  int? get perHundredAmountBasis {
    if (components.isEmpty) {
      return null;
    }

    final firstUnit = components.first.usedUnit;
    if (firstUnit == InventoryAmountUnit.piece) {
      return null;
    }

    var totalAmount = 0;
    for (final component in components) {
      if (component.usedUnit != firstUnit || component.usedAmount <= 0) {
        return null;
      }
      totalAmount += component.usedAmount;
    }

    if (totalAmount <= 0) {
      return null;
    }
    return totalAmount;
  }

  /// Multiplier that projects totals to a 100 g/ml basis when possible.
  double? get perHundredMultiplier {
    final amountBasis = perHundredAmountBasis;
    if (amountBasis == null || amountBasis <= 0) {
      return null;
    }
    return 100 / amountBasis;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreparedMeal &&
            other.id == id &&
            other.name == name &&
            other.imageAssetId == imageAssetId &&
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
      imageAssetId,
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

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
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

  factory PreparedMealComponent.fromJson(Map<String, dynamic> json) =>
      _$PreparedMealComponentFromJson(json);

  @JsonKey(fromJson: _readRequiredString)
  final String inventoryItemId;
  @JsonKey(fromJson: _readRequiredString)
  final String name;
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? brand;
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageUrl;
  @JsonKey(fromJson: _readIntOrZero)
  final int usedAmount;
  @JsonKey(fromJson: _readAmountUnitOrPiece, toJson: _writeAmountUnit)
  final InventoryAmountUnit usedUnit;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalKcal;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalProtein;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalCarbs;
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalFat;
  final InventoryItem sourceItemSnapshot;

  Map<String, dynamic> toJson() => _$PreparedMealComponentToJson(this);

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

  /// Cost contribution of this component based on the consumed share.
  double get totalPrice {
    if (usedAmount <= 0) {
      return 0;
    }

    if (sourceItemSnapshot.usesAmountProgress) {
      final initialAmount = sourceItemSnapshot.initialAmount;
      if (initialAmount <= 0) {
        return 0;
      }

      final initialQuantity = sourceItemSnapshot.initialQuantity > 0
          ? sourceItemSnapshot.initialQuantity
          : sourceItemSnapshot.quantity > 0
          ? sourceItemSnapshot.quantity
          : 1;
      final initialTotalPrice = sourceItemSnapshot.unitPrice * initialQuantity;
      return initialTotalPrice * (usedAmount / initialAmount);
    }

    return sourceItemSnapshot.unitPrice * usedAmount;
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

DateTime _readDateTimeOrNow(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return DateTime.now();
}

int _readIntOrZero(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

double _readDoubleOrZero(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

String _readRequiredString(Object? value) {
  return _readTrimmedNullableString(value) ?? '';
}

String? _readTrimmedNullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

InventoryAmountUnit _readAmountUnitOrPiece(Object? value) {
  final raw = value is String ? value.trim() : '';
  for (final unit in InventoryAmountUnit.values) {
    if (unit.code == raw) {
      return unit;
    }
  }
  return InventoryAmountUnit.piece;
}

String _writeAmountUnit(InventoryAmountUnit value) => value.code;

const Object _keepValue = Object();
