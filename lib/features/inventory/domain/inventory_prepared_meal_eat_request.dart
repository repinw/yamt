import 'package:yamt/core/domain/meal_type.dart';

/// Prepared meal eat request selected from the Inventory quick-eat surface.
class InventoryPreparedMealEatRequest {
  /// Creates a prepared meal eat request.
  const InventoryPreparedMealEatRequest({
    required this.portions,
    required this.mealType,
    required this.loggedDay,
  });

  /// Consumed portions.
  final num portions;

  /// Meal type for the calorie entry.
  final MealType mealType;

  /// Logged diary day.
  final DateTime loggedDay;
}
