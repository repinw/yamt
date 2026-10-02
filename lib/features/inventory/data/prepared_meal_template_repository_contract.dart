import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal template repository.
abstract interface class PreparedMealTemplateRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Reads all templates of the household and skips the ones that do
  /// not parse. Throws when they cannot be read.
  Future<List<PreparedMeal>> readAll();

  /// Save all.
  Future<bool> saveAll(List<PreparedMeal> templates);
}
