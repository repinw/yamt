import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Prepared meal eat request selected from the Inventory quick-eat surface.
class InventoryPreparedMealEatRequest {
  /// Creates a prepared meal eat request.
  const new({
    required this.meal,
    required this.portions,
    required this.mealType,
    required this.loggedDay,
    this.isPlan = false,
  });

  /// The meal as the page showed it on confirm.
  final PreparedMeal meal;

  /// Consumed portions.
  final num portions;

  /// Meal type for the calorie entry.
  final MealType mealType;

  /// Logged diary day.
  final DateTime loggedDay;

  /// Whether the user plans the meal instead of eating it, even on today.
  /// A day after today is always a plan.
  final bool isPlan;
}
