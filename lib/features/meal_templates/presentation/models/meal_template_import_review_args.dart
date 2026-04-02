import 'package:yamt/features/prepared_meals/data/'
    'prepared_meal_recipe_importer.dart';

class MealTemplateImportReviewArgs {
  const MealTemplateImportReviewArgs({
    required this.importedRecipe,
    required this.preferredName,
    required this.preferredPortions,
  });

  final PreparedMealRecipeImport importedRecipe;
  final String preferredName;
  final int? preferredPortions;
}
