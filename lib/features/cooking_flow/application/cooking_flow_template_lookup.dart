import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Finds cookflow template by id.
PreparedMeal? findCookingFlowTemplate(
  List<PreparedMeal> templates,
  String templateId,
) {
  for (final template in templates) {
    if (template.id == templateId) {
      return template;
    }
  }
  return null;
}
