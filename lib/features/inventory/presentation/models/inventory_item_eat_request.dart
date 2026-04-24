import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

/// Defines inventory item eat request.
class InventoryItemEatRequest {
  /// The inventory item eat request.
  const InventoryItemEatRequest({
    required this.inventoryAmount,
    required this.loggedAt,
    required this.mealType,
    this.calorieAmount,
    this.calorieUnit,
    this.portionBaseAmount,
    this.portionBaseUnit,
    this.portionCount,
    this.portionLabel,
  }) : assert(
         (calorieAmount == null) == (calorieUnit == null),
         'calorieAmount and calorieUnit must either both be null or set.',
       ),
       assert(
         (portionBaseAmount == null &&
                 portionBaseUnit == null &&
                 portionCount == null) ||
             (portionBaseAmount != null &&
                 portionBaseUnit != null &&
                 portionCount != null),
         'Portion amount, unit, and count must all be set together.',
       );

  /// The inventory amount.
  final int inventoryAmount;

  /// The logged at.
  final DateTime loggedAt;

  /// The meal type.
  final MealType mealType;

  /// The calorie amount.
  final double? calorieAmount;

  /// The calorie unit.
  final ConsumedUnit? calorieUnit;

  /// The learned base amount per portion.
  final double? portionBaseAmount;

  /// The learned base unit per portion.
  final ConsumedUnit? portionBaseUnit;

  /// The selected portion count.
  final double? portionCount;

  /// The user-facing portion label.
  final String? portionLabel;

  /// Whether manual calorie portion.
  bool get hasManualCaloriePortion {
    return calorieAmount != null && calorieUnit != null;
  }

  /// Whether request carries portion learning data.
  bool get hasPortionLearning {
    return portionBaseAmount != null &&
        portionBaseUnit != null &&
        portionCount != null;
  }
}
