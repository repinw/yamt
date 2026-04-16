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
  }) : assert(
         (calorieAmount == null) == (calorieUnit == null),
         'calorieAmount and calorieUnit must either both be null or set.',
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

  /// Whether manual calorie portion.
  bool get hasManualCaloriePortion {
    return calorieAmount != null && calorieUnit != null;
  }
}
