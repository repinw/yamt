import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_json.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

part 'prepared_meal.g.dart';

/// Defines recipe ingredient amount conversion.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class RecipeIngredientAmountConversion {
  /// The recipe ingredient amount conversion.
  const new({required this.amountPerPiece, required this.unit});

  /// Creates a [RecipeIngredientAmountConversion] for from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientAmountConversionFromJson(json);

  /// The amount per piece.
  @JsonKey(fromJson: readPreparedMealInt)
  final int amountPerPiece;

  /// The unit.
  @JsonKey(
    fromJson: readPreparedMealAmountUnit,
    toJson: writePreparedMealAmountUnit,
  )
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
  const new({
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
    this.recipeInstructions = const <String>[],
    this.ignoredRecipeIngredients = const <String>[],
    this.recipeIngredientAssignments = const <String, List<String>>{},
    this.recipeIngredientAmountConversions =
        const <String, RecipeIngredientAmountConversion>{},
    this.pendingRecipeIngredients = const <String>[],
    this.finalNetWeight,
    this.inPot,
    this.potTareWeight,
    this.servedInPieces,
    this.potWeighing,
  });

  /// Creates a [PreparedMeal] for from json.
  factory fromJson(Map<String, dynamic> json) => _$PreparedMealFromJson(json);

  /// The id.
  @JsonKey(fromJson: readPreparedMealString)
  final String id;

  /// The name.
  @JsonKey(fromJson: readPreparedMealString)
  final String name;

  /// The image asset id.
  @JsonKey(fromJson: readPreparedMealOptionalString)
  final String? imageAssetId;

  /// The image url.
  @JsonKey(fromJson: readPreparedMealOptionalString)
  final String? imageUrl;

  /// The recipe url.
  @JsonKey(fromJson: readPreparedMealOptionalString)
  final String? recipeUrl;

  /// The recipe ingredients.
  @JsonKey(defaultValue: <String>[])
  final List<String> recipeIngredients;

  /// The recipe instructions.
  @JsonKey(defaultValue: <String>[])
  final List<String> recipeInstructions;

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

  /// The cooked net weight in g/ml after tare.
  @JsonKey(fromJson: readPreparedMealOptionalInt)
  final int? finalNetWeight;

  /// `true` from "Kochen" on the free cooking page until the cook marks the
  /// meal as cooked; absent on every other meal.
  @JsonKey(includeIfNull: false)
  final bool? inPot;

  /// Empty weight in grams of the pot the meal was weighed in, so the pot can
  /// be weighed again when eating.
  @JsonKey(includeIfNull: false)
  final int? potTareWeight;

  /// `true` when one serving is a piece, such as a wrap, instead of a portion;
  /// absent on meals served in portions.
  @JsonKey(includeIfNull: false)
  final bool? servedInPieces;

  /// The last weighing of the pot while eating from it, shared with the
  /// household.
  @JsonKey(includeIfNull: false)
  final PreparedMealPotWeighing? potWeighing;

  /// Whether the meal is still cooking.
  bool get isInPot => inPot ?? false;

  /// Whether one serving of the meal is a piece.
  bool get isServedInPieces => servedInPieces ?? false;

  /// Remaining cooked net weight in g/ml.
  ///
  /// Always calculated dynamically from the cooked net weight and remaining
  /// portion ratio to prevent stale or desynchronized stored values.
  int? get remainingNetWeight {
    final netWeight = finalNetWeight;
    if (netWeight == null || netWeight < 1) {
      return null;
    }
    if (totalPortions < 1 || remainingPortions <= 0) {
      return 0;
    }
    return ((netWeight * remainingPortions) / totalPortions).round();
  }

  /// The total portions.
  @JsonKey(fromJson: readPreparedMealInt)
  final int totalPortions;

  /// The remaining portions.
  @JsonKey(fromJson: readPreparedMealDouble)
  final num remainingPortions;

  /// The total kcal.
  @JsonKey(fromJson: readPreparedMealDouble)
  final double totalKcal;

  /// The total protein.
  @JsonKey(fromJson: readPreparedMealDouble)
  final double totalProtein;

  /// The total carbs.
  @JsonKey(fromJson: readPreparedMealDouble)
  final double totalCarbs;

  /// The total fat.
  @JsonKey(fromJson: readPreparedMealDouble)
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
    List<String>? recipeInstructions,
    List<String>? ignoredRecipeIngredients,
    Map<String, List<String>>? recipeIngredientAssignments,
    Map<String, RecipeIngredientAmountConversion>?
    recipeIngredientAmountConversions,
    List<String>? pendingRecipeIngredients,
    Object? finalNetWeight = _keepValue,
    Object? inPot = _keepValue,
    Object? potTareWeight = _keepValue,
    Object? servedInPieces = _keepValue,
    Object? potWeighing = _keepValue,
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
      recipeInstructions: recipeInstructions ?? this.recipeInstructions,
      ignoredRecipeIngredients:
          ignoredRecipeIngredients ?? this.ignoredRecipeIngredients,
      recipeIngredientAssignments:
          recipeIngredientAssignments ?? this.recipeIngredientAssignments,
      recipeIngredientAmountConversions:
          recipeIngredientAmountConversions ??
          this.recipeIngredientAmountConversions,
      pendingRecipeIngredients:
          pendingRecipeIngredients ?? this.pendingRecipeIngredients,
      finalNetWeight: finalNetWeight == _keepValue
          ? this.finalNetWeight
          : finalNetWeight as int?,
      inPot: inPot == _keepValue ? this.inPot : inPot as bool?,
      potTareWeight: potTareWeight == _keepValue
          ? this.potTareWeight
          : potTareWeight as int?,
      servedInPieces: servedInPieces == _keepValue
          ? this.servedInPieces
          : servedInPieces as bool?,
      potWeighing: potWeighing == _keepValue
          ? this.potWeighing
          : potWeighing as PreparedMealPotWeighing?,
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
              other.recipeInstructions,
              recipeInstructions,
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
            other.finalNetWeight == finalNetWeight &&
            other.inPot == inPot &&
            other.potTareWeight == potTareWeight &&
            other.servedInPieces == servedInPieces &&
            other.potWeighing == potWeighing &&
            other.remainingNetWeight == remainingNetWeight &&
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
      const ListEquality<String>().hash(recipeInstructions),
      const ListEquality<String>().hash(ignoredRecipeIngredients),
      const DeepCollectionEquality().hash(recipeIngredientAssignments),
      const DeepCollectionEquality().hash(recipeIngredientAmountConversions),
      const ListEquality<String>().hash(pendingRecipeIngredients),
      finalNetWeight,
      inPot,
      potTareWeight,
      servedInPieces,
      potWeighing,
      remainingNetWeight,
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

/// A stored date and time, or now.
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

const Object _keepValue = Object();
