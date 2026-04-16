import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';

/// Defines meal template import review args.
class MealTemplateImportReviewArgs {
  /// The meal template import review args.
  const MealTemplateImportReviewArgs({
    required this.importedRecipe,
    required this.preferredName,
    required this.preferredPortions,
  });

  /// The imported recipe.
  final PreparedMealRecipeImport importedRecipe;

  /// The preferred name.
  final String preferredName;

  /// The preferred portions.
  final int? preferredPortions;
}
