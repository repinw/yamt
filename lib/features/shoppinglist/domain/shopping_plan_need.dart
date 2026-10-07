import 'package:yamt/core/domain/meal_type.dart';

/// A food that a plan needs and the stock cannot cover, proposed by a
/// data-owning feature.
class ShoppingPlanNeed {
  /// Creates the need.
  const new({
    required this.name,
    required this.day,
    required this.mealType,
    required this.amount,
    required this.inMilliliters,
    required this.isPartial,
    this.brand,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// The planned day.
  final DateTime day;

  /// The planned meal.
  final MealType mealType;

  /// The amount to buy, in grams or, with [inMilliliters], milliliters.
  final double amount;

  /// Whether [amount] counts milliliters.
  final bool inMilliliters;

  /// Whether the stock covers part of the plan, so [amount] is what is
  /// missing rather than the whole plan.
  final bool isPartial;
}

/// The needs of one meal on one day, in plan order.
typedef ShoppingPlanNeedGroup = ({
  DateTime day,
  MealType mealType,
  List<ShoppingPlanNeed> needs,
});
