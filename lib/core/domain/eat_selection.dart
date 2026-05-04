import 'package:yamt/core/domain/meal_type.dart';

/// Generic eat selection returned by product add flows.
class EatSelection {
  /// Creates a generic eat selection.
  const EatSelection({
    required this.inventoryAmount,
    required this.loggedAt,
    required this.mealType,
  });

  /// Inventory amount selected for the generated item.
  final int inventoryAmount;

  /// Date/time selected for logging.
  final DateTime loggedAt;

  /// Selected meal type.
  final MealType mealType;
}
