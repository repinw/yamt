import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_json.dart';
import 'package:yamt/features/inventory/domain/product_missing_values.dart';

part 'prepared_meal_component.g.dart';

/// Defines prepared meal component.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PreparedMealComponent {
  /// The prepared meal component.
  const new({
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
    this.addedForMeal,
    this.pendingRecipeIngredient,
  });

  /// Creates a [PreparedMealComponent] for from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$PreparedMealComponentFromJson(json);

  /// The inventory item id.
  @JsonKey(fromJson: readPreparedMealString)
  final String inventoryItemId;

  /// The name.
  @JsonKey(fromJson: readPreparedMealString)
  final String name;

  /// The brand.
  @JsonKey(fromJson: readPreparedMealOptionalString)
  final String? brand;

  /// The image url.
  @JsonKey(fromJson: readPreparedMealOptionalString)
  final String? imageUrl;

  /// The used amount.
  @JsonKey(fromJson: readPreparedMealInt)
  final int usedAmount;

  /// The used unit.
  @JsonKey(
    fromJson: readPreparedMealAmountUnit,
    toJson: writePreparedMealAmountUnit,
  )
  final InventoryAmountUnit usedUnit;

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

  /// The source item snapshot.
  final InventoryItem sourceItemSnapshot;

  /// `true` when the Vorrat item was added only for this meal, such as a
  /// food found by search while combining; discarding the meal before its
  /// "Gekocht" step deletes it again. Absent on every other component.
  @JsonKey(includeIfNull: false)
  final bool? addedForMeal;

  /// Whether the Vorrat item was added only for this meal.
  bool get isAddedForMeal => addedForMeal ?? false;

  /// The open row of the meal that this food fills, such as "200 g Reis".
  /// Absent on foods that fill no row.
  @JsonKey(includeIfNull: false)
  final String? pendingRecipeIngredient;

  /// The open row this food leaves when it is taken out of the meal again:
  /// the row it fills, else its own amount and name, such as "200 g Reis".
  String get openRow {
    if (pendingRecipeIngredient case final row?) {
      return row;
    }
    final amount = preparedMealComponentDisplayAmount(this)
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$amount ${usedUnit.code} $name';
  }

  /// Nutrients of [usedAmount]. Energy and the macros are the totals the
  /// meal counts; the other values come from the source item's label, and
  /// a value the label lacks is null.
  NutritionFacts get nutritionFacts {
    final label = sourceItemSnapshot.nutrition;
    final factor = preparedMealNutritionFactor(
      item: sourceItemSnapshot,
      amount: usedAmount,
      unit: usedUnit,
    );
    double? scaled(double? per100) => per100 == null ? null : per100 * factor;
    return NutritionFacts(
      kcal: totalKcal,
      fat: totalFat,
      saturatedFat: scaled(label?.per100SaturatedFat),
      polyunsaturatedFat: scaled(label?.per100PolyunsaturatedFat),
      carbs: totalCarbs,
      sugar: scaled(label?.per100Sugar),
      fiber: scaled(label?.per100Fiber),
      protein: totalProtein,
      salt: scaled(label?.per100Salt),
    );
  }

  /// Whether the source item's label lacks a value of the EU nutrition
  /// label, so the meal's nutrients may leave it out.
  bool get hasIncompleteNutrition =>
      missingNutritionValues(sourceItemSnapshot.nutrition).isNotEmpty;

  /// The internal storage scale of [usedAmount], taken from the source
  /// item. Piece-tracked items store fractional pieces multiplied by
  /// [inventoryPieceAmountScale].
  int get usedAmountScale => sourceItemSnapshot.amountScale;

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
    bool? addedForMeal,
    String? pendingRecipeIngredient,
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
      addedForMeal: addedForMeal ?? this.addedForMeal,
      pendingRecipeIngredient:
          pendingRecipeIngredient ?? this.pendingRecipeIngredient,
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
            other.sourceItemSnapshot == sourceItemSnapshot &&
            other.addedForMeal == addedForMeal &&
            other.pendingRecipeIngredient == pendingRecipeIngredient;
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
      addedForMeal,
      pendingRecipeIngredient,
    );
  }
}

/// The factor that turns the per-100 values of [item] into the nutrients of
/// [amount] of it in [unit]: a hundredth of grams or milliliters, or the
/// count of pieces.
double preparedMealNutritionFactor({
  required InventoryItem item,
  required int amount,
  required InventoryAmountUnit unit,
}) {
  if (unit == InventoryAmountUnit.piece) {
    return inventoryAmountToDisplayValue(
      amount: amount,
      unit: unit,
      scale: item.usesAmountProgress ? item.amountScale : 1,
    );
  }
  return amount / 100;
}

/// Converts a raw amount of [component] (its [PreparedMealComponent.usedAmount]
/// or a value derived from it, for example scaled by a portion ratio) into a
/// value fit to display, undoing the fractional-piece storage scale of its
/// source item. Unlike [inventoryAmountToDisplayValue], [rawAmount] may be
/// fractional (a portion-scaled amount) without being rounded first, so
/// gram and milliliter amounts keep their precision.
double preparedMealComponentDisplayAmount(
  PreparedMealComponent component, [
  num? rawAmount,
]) {
  final amount = rawAmount ?? component.usedAmount;
  final safeAmount = amount < 0 ? 0 : amount;
  final scale = component.usedAmountScale;
  if (!inventoryAmountAllowsFractionalInput(
    unit: component.usedUnit,
    scale: scale,
  )) {
    return safeAmount.toDouble();
  }
  final safeScale = scale < 1 ? 1 : scale;
  return safeAmount / safeScale;
}

const Object _keepValue = Object();
