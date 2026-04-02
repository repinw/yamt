import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_scraper/recipe_scraper.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_recipe_import_formatter.dart';

class PreparedMealRecipeImport {
  const PreparedMealRecipeImport({
    required this.recipeUrl,
    this.imageUrl,
    required this.title,
    required this.servings,
    required this.ingredients,
    this.instructionsPreview = const <String>[],
  });

  final String recipeUrl;
  final String? imageUrl;
  final String title;
  final int servings;
  final List<String> ingredients;
  final List<String> instructionsPreview;
}

class PreparedMealRecipeImporter {
  const PreparedMealRecipeImporter({
    this.formatter = const PreparedMealRecipeImportFormatter(),
  });

  final PreparedMealRecipeImportFormatter formatter;

  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    final recipe = await scrapeRecipe(recipeUrl);
    if (recipe == null) {
      return null;
    }

    return PreparedMealRecipeImport(
      recipeUrl: recipe.url,
      imageUrl: formatter.normalizeRecipeImageUrl(
        recipe.imageUrls.isEmpty ? null : recipe.imageUrls.first,
      ),
      title: recipe.title.trim(),
      servings: recipe.servings,
      ingredients: recipe.ingredients
          .map(
            (ingredient) => formatter.formatIngredientLine(
              ingredient,
              localeName: localeName,
            ),
          )
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
      instructionsPreview: recipe.instructions
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList(growable: false),
    );
  }
}

final preparedMealRecipeImporterProvider = Provider<PreparedMealRecipeImporter>(
  (ref) {
    return const PreparedMealRecipeImporter();
  },
);
