import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// The kcal of one meal in the meals tile.
@immutable
class DiaryMealKcal {
  /// Creates the kcal of [mealType].
  const new({
    required this.mealType,
    required this.eaten,
    required this.planned,
  });

  /// The meal.
  final MealType mealType;

  /// Eaten kcal.
  final double eaten;

  /// Planned kcal the meal heading counts on top of [eaten].
  final double planned;

  /// The kcal the meal heading shows.
  double get total => eaten + planned;
}
