import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal template repository.
abstract interface class PreparedMealTemplateRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Read all.
  Future<List<PreparedMeal>> readAll();

  /// Save all.
  Future<bool> saveAll(List<PreparedMeal> templates);
}
