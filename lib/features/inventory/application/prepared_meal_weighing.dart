import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

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
  }) async {
    final meals = await _writer.loadMeals();
    final index = meals.indexWhere((meal) => meal.id == mealId);
    if (index < 0) {
      throw StateError('Meal $mealId is gone.');
    }
    final meal = meals[index];
    if (meal.potTareWeight == null || netWeight < 1) {
      throw StateError('Meal $mealId was not weighed in its pot.');
    }
    final now = _writer.buildNow();
    final weighed = meal.copyWith(
      potWeighing: PreparedMealPotWeighing(
        netWeight: netWeight,
        weighedAt: now,
        remainingPortions: meal.remainingPortions,
      ),
      updatedAt: now,
    );
    final saved = await _writer.saveMeals(
      previousMeals: meals,
      nextMeals: [...meals]..[index] = weighed,
    );
    if (!saved) {
      throw StateError('Pot weighing of $mealId could not be saved.');
    }
    return weighed;
  }
}
