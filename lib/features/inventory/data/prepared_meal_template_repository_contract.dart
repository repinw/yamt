import 'package:yamt/features/inventory/domain/prepared_meal.dart';

abstract interface class PreparedMealTemplateRepository {
  Stream<List<PreparedMeal>> watchAll();

  Future<List<PreparedMeal>> readAll();

  Future<bool> saveAll(List<PreparedMeal> templates);
}
