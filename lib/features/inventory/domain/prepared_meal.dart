import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'prepared_meal.g.dart';

/// Defines recipe ingredient amount conversion.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RecipeIngredientAmountConversion {
  /// The recipe ingredient amount conversion.
  const RecipeIngredientAmountConversion({
    required this.amountPerPiece,
    required this.unit,
  });

  /// Creates a [RecipeIngredientAmountConversion] for from json.
  factory RecipeIngredientAmountConversion.fromJson(
    Map<String, dynamic> json,
  ) => _$RecipeIngredientAmountConversionFromJson(json);

  /// The amount per piece.
  @JsonKey(fromJson: _readIntOrZero)
  final int amountPerPiece;

  /// The unit.
  @JsonKey(fromJson: _readAmountUnitOrPiece, toJson: _writeAmountUnit)
  final InventoryAmountUnit unit;

  /// To json.
  Map<String, dynamic> toJson() =>
      _$RecipeIngredientAmountConversionToJson(this);

  /// Copy with.
  RecipeIngredientAmountConversion copyWith({
    int? amountPerPiece,
    InventoryAmountUnit? unit,
  }) {
    return RecipeIngredientAmountConversion(
      amountPerPiece: amountPerPiece ?? this.amountPerPiece,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecipeIngredientAmountConversion &&
            other.amountPerPiece == amountPerPiece &&
            other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(amountPerPiece, unit);
}

/// Defines prepared meal.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PreparedMeal {
  /// The prepared meal.
  const PreparedMeal({
    required this.id,
    required this.name,
    required this.totalPortions,
    required this.remainingPortions,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.createdAt,
    required this.updatedAt,
    required this.components,
    this.imageAssetId,
    this.imageUrl,
    this.recipeUrl,
    this.recipeIngredients = const <String>[],
    this.ignoredRecipeIngredients = const <String>[],
    this.recipeIngredientAssignments = const <String, List<String>>{},
    this.recipeIngredientAmountConversions =
        const <String, RecipeIngredientAmountConversion>{},
    this.pendingRecipeIngredients = const <String>[],
  });

  /// Creates a [PreparedMeal] for from json.
  factory PreparedMeal.fromJson(Map<String, dynamic> json) =>
      _$PreparedMealFromJson(json);

  /// The id.
  @JsonKey(fromJson: _readRequiredString)
  final String id;

  /// The name.
  @JsonKey(fromJson: _readRequiredString)
  final String name;

  /// The image asset id.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageAssetId;

  /// The image url.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageUrl;

  /// The recipe url.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? recipeUrl;

  /// The recipe ingredients.
  @JsonKey(defaultValue: <String>[])
  final List<String> recipeIngredients;

  /// The ignored recipe ingredients.
  @JsonKey(defaultValue: <String>[])
  final List<String> ignoredRecipeIngredients;

  /// The recipe ingredient assignments.
  @JsonKey(defaultValue: <String, List<String>>{})
  final Map<String, List<String>> recipeIngredientAssignments;

  /// Documented member.
  @JsonKey(defaultValue: <String, RecipeIngredientAmountConversion>{})
  final Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions;

  /// The pending recipe ingredients.
  @JsonKey(defaultValue: <String>[])
  final List<String> pendingRecipeIngredients;

  /// The total portions.
  @JsonKey(fromJson: _readIntOrZero)
  final int totalPortions;

  /// The remaining portions.
  @JsonKey(fromJson: _readDoubleOrZero)
  final num remainingPortions;

  /// The total kcal.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalKcal;

  /// The total protein.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalProtein;

  /// The total carbs.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalCarbs;

  /// The total fat.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalFat;

  /// The created at.
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime createdAt;

  /// The updated at.
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime updatedAt;

  /// The components.
  @JsonKey(defaultValue: <PreparedMealComponent>[])
  final List<PreparedMealComponent> components;

  /// To json.
  Map<String, dynamic> toJson() => _$PreparedMealToJson(this);

  /// Copy with.
  PreparedMeal copyWith({
    String? id,
    String? name,
    Object? imageAssetId = _keepValue,
    Object? imageUrl = _keepValue,
    Object? recipeUrl = _keepValue,
    List<String>? recipeIngredients,
    List<String>? ignoredRecipeIngredients,
    Map<String, List<String>>? recipeIngredientAssignments,
    Map<String, RecipeIngredientAmountConversion>?
    recipeIngredientAmountConversions,
    List<String>? pendingRecipeIngredients,
    int? totalPortions,
    num? remainingPortions,
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
      imageUrl: imageUrl == _keepValue ? this.imageUrl : imageUrl as String?,
      recipeUrl: recipeUrl == _keepValue
          ? this.recipeUrl
          : recipeUrl as String?,
      recipeIngredients: recipeIngredients ?? this.recipeIngredients,
      ignoredRecipeIngredients:
          ignoredRecipeIngredients ?? this.ignoredRecipeIngredients,
      recipeIngredientAssignments:
          recipeIngredientAssignments ?? this.recipeIngredientAssignments,
      recipeIngredientAmountConversions:
          recipeIngredientAmountConversions ??
          this.recipeIngredientAmountConversions,
      pendingRecipeIngredients:
          pendingRecipeIngredients ?? this.pendingRecipeIngredients,
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

  /// Whether depleted.
  bool get isDepleted => remainingPortions <= 0;

  /// Whether pending recipe ingredients.
  bool get hasPendingRecipeIngredients => pendingRecipeIngredients.isNotEmpty;

  /// The remaining ratio.
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

  /// Shared currency across all priced components when available.
  String? get currencyCode {
    return resolveSharedCurrencyCode(
      components.map((component) => component.sourceItemSnapshot.currencyCode),
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
            other.imageUrl == imageUrl &&
            other.recipeUrl == recipeUrl &&
            const ListEquality<String>().equals(
              other.recipeIngredients,
              recipeIngredients,
            ) &&
            const ListEquality<String>().equals(
              other.ignoredRecipeIngredients,
              ignoredRecipeIngredients,
            ) &&
            const DeepCollectionEquality().equals(
              other.recipeIngredientAssignments,
              recipeIngredientAssignments,
            ) &&
            const DeepCollectionEquality().equals(
              other.recipeIngredientAmountConversions,
              recipeIngredientAmountConversions,
            ) &&
            const ListEquality<String>().equals(
              other.pendingRecipeIngredients,
              pendingRecipeIngredients,
            ) &&
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
      imageUrl,
      recipeUrl,
      const ListEquality<String>().hash(recipeIngredients),
      const ListEquality<String>().hash(ignoredRecipeIngredients),
      const DeepCollectionEquality().hash(recipeIngredientAssignments),
      const DeepCollectionEquality().hash(recipeIngredientAmountConversions),
      const ListEquality<String>().hash(pendingRecipeIngredients),
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

/// Formats prepared meal portion values without noisy trailing zeroes.
String formatPreparedMealPortions(num portions) {
  final asDouble = portions.toDouble();
  final rounded = asDouble.roundToDouble();
  if ((asDouble - rounded).abs() < 0.000001) {
    return rounded.toInt().toString();
  }
  return asDouble
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Defines prepared meal component.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PreparedMealComponent {
  /// The prepared meal component.
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

  /// Creates a [PreparedMealComponent] for from json.
  factory PreparedMealComponent.fromJson(Map<String, dynamic> json) =>
      _$PreparedMealComponentFromJson(json);

  /// The inventory item id.
  @JsonKey(fromJson: _readRequiredString)
  final String inventoryItemId;

  /// The name.
  @JsonKey(fromJson: _readRequiredString)
  final String name;

  /// The brand.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? brand;

  /// The image url.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageUrl;

  /// The used amount.
  @JsonKey(fromJson: _readIntOrZero)
  final int usedAmount;

  /// The used unit.
  @JsonKey(fromJson: _readAmountUnitOrPiece, toJson: _writeAmountUnit)
  final InventoryAmountUnit usedUnit;

  /// The total kcal.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalKcal;

  /// The total protein.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalProtein;

  /// The total carbs.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalCarbs;

  /// The total fat.
  @JsonKey(fromJson: _readDoubleOrZero)
  final double totalFat;

  /// The source item snapshot.
  final InventoryItem sourceItemSnapshot;

  /// To json.
  Map<String, dynamic> toJson() => _$PreparedMealComponentToJson(this);

  /// Copy with.
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

      final initialQuantity = sourceItemSnapshot.effectiveInitialQuantity;
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
