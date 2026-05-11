import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_scraper/recipe_scraper.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_import_formatter.dart';

/// Defines prepared meal recipe import.
class PreparedMealRecipeImport {
  /// The prepared meal recipe import.
  const PreparedMealRecipeImport({
    required this.recipeUrl,
    required this.title,
    required this.servings,
    required this.ingredients,
    this.imageUrl,
    this.instructions = const <String>[],
    this.instructionsPreview = const <String>[],
  });

  /// The recipe url.
  final String recipeUrl;

  /// The image url.
  final String? imageUrl;

  /// The title.
  final String title;

  /// The servings.
  final int servings;

  /// The ingredients.
  final List<String> ingredients;

  /// The full instructions.
  final List<String> instructions;

  /// The instructions preview.
  final List<String> instructionsPreview;
}

/// Defines prepared meal recipe importer.
class PreparedMealRecipeImporter {
  /// The prepared meal recipe importer.
  const PreparedMealRecipeImporter({
    this.formatter = const PreparedMealRecipeImportFormatter(),
  });

  /// The formatter.
  final PreparedMealRecipeImportFormatter formatter;

  /// Import recipe.
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
      instructions: recipe.instructions
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
      instructionsPreview: recipe.instructions
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList(growable: false),
    );
  }
}

/// The prepared meal recipe importer provider.
final preparedMealRecipeImporterProvider = Provider<PreparedMealRecipeImporter>(
  (ref) {
    return const PreparedMealRecipeImporter();
  },
);
