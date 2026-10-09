import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Turns a Vorrat meal into a cookbook template.
extension PreparedMealTemplateCopy on PreparedMeal {
  /// A template with [id] that keeps this meal's ingredients and amounts,
  /// with every portion left and without the last pot weighing.
  PreparedMeal asTemplate({required String id, required DateTime now}) =>
      copyWith(
        id: id,
        name: name.trim(),
        remainingPortions: totalPortions,
        potWeighing: null,
        createdAt: now,
        updatedAt: now,
      );
}
