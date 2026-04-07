import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

class InventoryItemEatRequest {
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

  final int inventoryAmount;
  final DateTime loggedAt;
  final MealType mealType;
  final double? calorieAmount;
  final ConsumedUnit? calorieUnit;

  bool get hasManualCaloriePortion {
    return calorieAmount != null && calorieUnit != null;
  }
}
