import 'package:yamt/features/meal_templates/domain/meal_template_ingredient.dart';

enum MealTemplateSourceType { chefkoch, inventoryMeal, manual }

class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.basePortions,
    required this.createdAt,
    required this.updatedAt,
    required this.ingredients,
    this.sourceUrl,
    this.imageUrl,
    this.instructionsPreview,
  });

  final String id;
  final String name;
  final MealTemplateSourceType sourceType;
  final String? sourceUrl;
  final String? imageUrl;
  final int basePortions;
  final String? instructionsPreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MealTemplateIngredient> ingredients;
}
