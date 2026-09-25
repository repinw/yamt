import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_amount_step.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';

const _fractionalPieceStep = 0.25;

/// Input errors the item eat sheet shows next to its fields.
enum InventoryItemEatSheetError {
  /// The inventory amount is missing or larger than the stock.
  invalidInventoryAmount,

  /// The inedible amount is not a number.
  invalidInedibleAmount,

  /// The inedible amount is not smaller than the eaten amount.
  inedibleTooLarge,

  /// The portion count is not a positive number.
  invalidPortionCount,

  /// The portion amount is not a positive number.
  invalidPortionAmount,
}

/// A named amount of a fixed-unit item, for example "Slice = 30 g".
@immutable
final class InventoryItemEatPortion {
  /// Creates a portion of [amount] [unit].
  const new({required this.amount, required this.unit, this.label});

  /// Amount in one portion.
  final double amount;

  /// Unit of [amount].
  final ConsumedUnit unit;

  /// Optional portion name, for example "Slice".
  final String? label;

  String get _labelKey => label?.trim().toLowerCase() ?? '';

  @override
  bool operator ==(Object other) {
    return other is InventoryItemEatPortion &&
        other.unit == unit &&
        buildServingSuggestionAmountKey(other.amount) ==
            buildServingSuggestionAmountKey(amount) &&
        other._labelKey == _labelKey;
  }

  @override
  int get hashCode =>
      Object.hash(unit, buildServingSuggestionAmountKey(amount), _labelKey);
}

/// State of the inventory item eat sheet.
@immutable
class InventoryItemEatSheetState {
  /// Creates the sheet state.
  const new({
    required this.calculator,
    required this.inventoryAmountText,
    required this.portionCountText,
    required this.portionAmountText,
    required this.portionUnit,
    required this.portionLabel,
    required this.inedibleAmountText,
    required this.isInedibleExpanded,
    required this.loggedAt,
    required this.today,
    required this.mealType,
    required this.markers,
    required this.rememberedPortions,
    required this.pieceSizes,
    required this.nutrition,
    required this.errors,
    required this.didEditInventoryAmount,
    required this.didEditPortion,
  });

  /// Amount rules of the item.
  final InventoryItemEatCalculator calculator;

  /// Text of the inventory amount field.
  final String inventoryAmountText;

  /// Text of the portion count field.
  final String portionCountText;

  /// Amount in one portion, as entered.
  final String portionAmountText;

  /// Unit of the portion amount.
  final ConsumedUnit portionUnit;

  /// Name of the current portion, or null for the default name.
  final String? portionLabel;

  /// Text of the inedible amount field.
  final String inedibleAmountText;

  /// Whether the inedible section is open.
  final bool isInedibleExpanded;

  /// When the food is logged.
  final DateTime loggedAt;

  /// The current day.
  final DateTime today;

  /// Meal the food is logged to.
  final MealType mealType;

  /// Marks on the amount ruler, in the unit of the amount field.
  final List<InventoryItemEatMarker> markers;

  /// Portions the user named in this sheet, or piece sizes in portion
  /// mode. They are saved with the food.
  final List<InventoryItemEatPortion> rememberedPortions;

  /// Known weights of one piece in portion mode, such as egg sizes.
  final List<InventoryItemEatPortion> pieceSizes;

  /// Nutrition of the entered amount, or null when it is unknown.
  final EatNutrition? nutrition;

  /// Errors to show.
  final Set<InventoryItemEatSheetError> errors;

  /// Whether the user changed the inventory amount.
  final bool didEditInventoryAmount;

  /// Whether the user changed the portion.
  final bool didEditPortion;

  /// Whether the amount field holds a piece count. Items without a weight
  /// unit need the weight of one piece to be logged.
  bool get usesPortionMode => calculator.requiresManualCaloriePortion;

  /// Current portion input, or null outside portion mode.
  InventoryItemEatPortionInput? get portionInput {
    return calculator.parsePortionInput(
      usesPortionMode: usesPortionMode,
      countText: portionCountText,
      amountText: portionAmountText,
      unit: portionUnit,
    );
  }

  /// Largest value of the amount ruler: the stock, in pieces in portion
  /// mode.
  double get amountMax {
    final max = calculator.maxAmount.toDouble();
    return usesPortionMode ? max / calculator.inventoryAmountScale : max;
  }

  /// Value of the amount field on the ruler, or 0 when it cannot be parsed.
  double get amountValue {
    if (usesPortionMode) {
      return parsePositiveDecimalInput(portionCountText) ?? 0;
    }
    return (enteredInventoryAmount ?? 0).toDouble();
  }

  /// Step the amount ruler snaps to.
  double get amountStep {
    if (usesPortionMode) {
      return calculator.allowsFractionalInventoryAmount
          ? _fractionalPieceStep
          : 1;
    }
    return eatAmountStep(calculator.maxAmount).toDouble();
  }

  /// Piece size that matches the entered weight and name, if any.
  InventoryItemEatPortion? get selectedPieceSize {
    final weight = parsePositiveDecimalInput(portionAmountText);
    if (!usesPortionMode || weight == null) {
      return null;
    }
    return pieceSizes
        .where(
          (size) =>
              size ==
              InventoryItemEatPortion(
                amount: weight,
                unit: portionUnit,
                label: portionLabel,
              ),
        )
        .firstOrNull;
  }

  /// Inventory amount parsed from the field, in inventory mode.
  int? get enteredInventoryAmount {
    return calculator.parseInventoryAmount(inventoryAmountText);
  }

  /// Inedible amount parsed from the field.
  double? get inedibleAmount {
    return parseNonNegativeDecimalInput(inedibleAmountText.trim());
  }

  /// Creates a copy with the given fields replaced.
  InventoryItemEatSheetState copyWith({
    String? inventoryAmountText,
    String? portionCountText,
    String? portionAmountText,
    ConsumedUnit? portionUnit,
    String? Function()? portionLabel,
    String? inedibleAmountText,
    bool? isInedibleExpanded,
    DateTime? loggedAt,
    MealType? mealType,
    List<InventoryItemEatMarker>? markers,
    List<InventoryItemEatPortion>? rememberedPortions,
    List<InventoryItemEatPortion>? pieceSizes,
    EatNutrition? Function()? nutrition,
    Set<InventoryItemEatSheetError>? errors,
    bool? didEditInventoryAmount,
    bool? didEditPortion,
  }) {
    return InventoryItemEatSheetState(
      calculator: calculator,
      inventoryAmountText: inventoryAmountText ?? this.inventoryAmountText,
      portionCountText: portionCountText ?? this.portionCountText,
      portionAmountText: portionAmountText ?? this.portionAmountText,
      portionUnit: portionUnit ?? this.portionUnit,
      portionLabel: portionLabel == null ? this.portionLabel : portionLabel(),
      inedibleAmountText: inedibleAmountText ?? this.inedibleAmountText,
      isInedibleExpanded: isInedibleExpanded ?? this.isInedibleExpanded,
      loggedAt: loggedAt ?? this.loggedAt,
      today: today,
      mealType: mealType ?? this.mealType,
      markers: markers ?? this.markers,
      rememberedPortions: rememberedPortions ?? this.rememberedPortions,
      pieceSizes: pieceSizes ?? this.pieceSizes,
      nutrition: nutrition == null ? this.nutrition : nutrition(),
      errors: errors ?? this.errors,
      didEditInventoryAmount:
          didEditInventoryAmount ?? this.didEditInventoryAmount,
      didEditPortion: didEditPortion ?? this.didEditPortion,
    );
  }
}
