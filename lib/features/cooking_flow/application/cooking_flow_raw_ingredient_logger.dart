import 'dart:developer' as developer;

import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Logs raw recipe ingredients once per template.
class CookingFlowRawIngredientLogger {
  final Set<String> _loggedTemplateIds = <String>{};

  /// Logs raw ingredient strings for debug inspection.
  void logTemplate(PreparedMeal template) {
    if (!_loggedTemplateIds.add(template.id)) {
      return;
    }
    developer.log(
      'Opening cookflow for template "${template.name}" '
      '(${template.recipeIngredients.length} raw ingredients)',
      name: 'cookflow.raw_ingredients',
    );
    for (var index = 0; index < template.recipeIngredients.length; index++) {
      final ingredient = template.recipeIngredients[index];
      developer.log(
        '[$index] "$ingredient" codeUnits=${ingredient.codeUnits.join(',')}',
        name: 'cookflow.raw_ingredients',
      );
    }
  }
}
