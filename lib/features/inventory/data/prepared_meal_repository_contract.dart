import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal repository.
abstract interface class PreparedMealRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Reads all meals of the household and skips the ones that do
  /// not parse. Throws when they cannot be read.
  Future<List<PreparedMeal>> readAll();

  /// Save all.
  Future<bool> saveAll(List<PreparedMeal> meals);
}
