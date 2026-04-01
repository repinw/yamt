import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_scraper/recipe_scraper.dart';

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
  const PreparedMealRecipeImporter();

  Future<PreparedMealRecipeImport?> importRecipe(String recipeUrl) async {
    final recipe = await scrapeRecipe(recipeUrl);
    if (recipe == null) {
      return null;
    }

    return PreparedMealRecipeImport(
      recipeUrl: recipe.url,
      imageUrl: _normalizeRecipeImageUrl(
        recipe.imageUrls.isEmpty ? null : recipe.imageUrls.first,
      ),
      title: recipe.title.trim(),
      servings: recipe.servings,
      ingredients: recipe.ingredients
          .map(_formatIngredientLine)
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
      instructionsPreview: recipe.instructions
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList(growable: false),
    );
  }

  String _formatIngredientLine(Ingredient ingredient) {
    final parts = <String>[];
    final quantity = _formatQuantity(ingredient.quantity);
    if (quantity.isNotEmpty) {
      parts.add(quantity);
    }
    final unit = ingredient.unit?.trim();
    if (unit != null && unit.isNotEmpty) {
      parts.add(unit);
    }
    final name = ingredient.name.trim();
    if (name.isNotEmpty) {
      parts.add(name);
    }
    return parts.join(' ').trim();
  }

  String _formatQuantity(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString().replaceAll('.', ',');
  }

  String? _normalizeRecipeImageUrl(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }
}

final preparedMealRecipeImporterProvider = Provider<PreparedMealRecipeImporter>(
  (ref) {
    return const PreparedMealRecipeImporter();
  },
);
