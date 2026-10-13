import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

/// Stores a weighing of the pot of a cooked meal.
class PreparedMealWeighing {
  /// Creates the weighing change.
  const new({required this._writer});

  final PreparedMealWriter _writer;

  /// Stores that the pot of the cooked meal [mealId] holds [netWeight] grams
  /// of food now. Returns the meal with the weighing. Throws when the meal
  /// is gone, was not weighed in its pot, or the write fails.
  Future<PreparedMeal> weighPot({
    required String mealId,
    required int netWeight,
  }) => _replaceMeal(mealId, (meal, now) {
    if (meal.potTareWeight == null || netWeight < 1) {
      throw StateError('Meal $mealId was not weighed in its pot.');
    }
    return meal.withFoodWeighed(netWeight, now);
  });

  /// Writes the meal [mealId] as [change] returns it at the current time,
  /// and returns the written meal. Throws when the meal is gone, [change]
  /// throws, or the write fails.
  Future<PreparedMeal> _replaceMeal(
    String mealId,
    PreparedMeal Function(PreparedMeal meal, DateTime now) change,
  ) async {
    final meals = await _writer.loadMeals();
    final index = meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) {
      throw StateError('Meal $mealId is gone.');
    }
    final changed = change(meals[index], _writer.buildNow());
    final saved = await _writer.saveMeals(
      previousMeals: meals,
      nextMeals: [...meals]..[index] = changed,
    );
    if (!saved) {
      throw StateError('Meal $mealId could not be saved.');
    }
    return changed;
  }
}
