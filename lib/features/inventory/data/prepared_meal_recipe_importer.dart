import 'dart:convert';
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_html_parser.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_import_formatter.dart';

part 'prepared_meal_recipe_importer.g.dart';

const _recipeImporterLogName = 'PreparedMealRecipeImporter';

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
    this.parser = const PreparedMealRecipeHtmlParser(),
    this.client,
  });

  /// The parser used to extract recipe data from HTML.
  final PreparedMealRecipeHtmlParser parser;

  /// The formatter used for ingredients and image URLs.
  PreparedMealRecipeImportFormatter get formatter => parser.formatter;

  /// Optional http client for testing.
  final http.Client? client;

  /// Import recipe.
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    try {
      final uri = Uri.tryParse(recipeUrl.trim());
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return null;
      }

      final httpClient = client ?? http.Client();
      final http.Response response;
      try {
        response = await httpClient.get(
          uri,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7',
          },
        ).timeout(const Duration(seconds: 15));
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }

      if (response.statusCode != 200) {
        return null;
      }

      final htmlBody = _decodeResponseBody(response);
      return parser.parse(
        html: htmlBody,
        recipeUrl: recipeUrl,
        localeName: localeName,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to import recipe from $recipeUrl',
        name: _recipeImporterLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static String _decodeResponseBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on Object catch (_) {
      return response.body;
    }
  }
}

/// The prepared meal recipe importer provider.
@Riverpod(keepAlive: true)
PreparedMealRecipeImporter preparedMealRecipeImporter(Ref ref) {
  return const PreparedMealRecipeImporter();
}
