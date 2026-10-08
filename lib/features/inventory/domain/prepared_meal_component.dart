import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_json.dart';

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
