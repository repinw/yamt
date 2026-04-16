import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal repository.
abstract interface class PreparedMealRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Read all.
  Future<List<PreparedMeal>> readAll();

  /// Save all.
  Future<bool> saveAll(List<PreparedMeal> meals);
}
