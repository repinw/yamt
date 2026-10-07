import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal repository.
abstract interface class PreparedMealRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Reads all meals of the household and skips the ones that do
  /// not parse. Throws when they cannot be read.
  Future<List<PreparedMeal>> readAll();

  /// Writes [meal] alone; the other meals of the household stay untouched.
  Future<bool> save(PreparedMeal meal);

  /// Deletes the meal [mealId] alone.
  Future<bool> delete(String mealId);
}

/// Writes a list change one meal at a time.
extension PreparedMealListChanges on PreparedMealRepository {
  /// Saves the meals of [next] that differ from [previous] and deletes the
  /// ones that [next] leaves out. Meals in neither list stay untouched.
  Future<bool> saveChanges({
    required List<PreparedMeal> previous,
    required List<PreparedMeal> next,
  }) async {
    final before = {for (final meal in previous) meal.id: meal};
    final nextIds = {for (final meal in next) meal.id};
    var saved = true;
    for (final meal in next) {
      if (before[meal.id] != meal) {
        saved = await save(meal) && saved;
      }
    }
    for (final id in before.keys) {
      if (!nextIds.contains(id)) {
        saved = await delete(id) && saved;
      }
    }
    return saved;
  }
}
