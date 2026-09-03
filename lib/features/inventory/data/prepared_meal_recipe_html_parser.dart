import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yamt/features/inventory/data/prepared_meal_recipe_import_formatter.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';

/// Parses recipe JSON-LD structured data from HTML documents.
class PreparedMealRecipeHtmlParser {
  /// Creates a recipe HTML parser.
  const PreparedMealRecipeHtmlParser({
    this.formatter = const PreparedMealRecipeImportFormatter(),
  });

  /// The formatter used for ingredients and image URLs.
  final PreparedMealRecipeImportFormatter formatter;

  /// Parses an HTML document and extracts recipe import data.
  PreparedMealRecipeImport? parse({
    required String html,
    required String recipeUrl,
    String? localeName,
  }) {
    final document = html_parser.parse(html);
    final scriptTags = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );

    for (final scriptTag in scriptTags) {
      final text = scriptTag.text.trim();
      if (text.isEmpty) {
        continue;
      }

      final dynamic jsonData;
      try {
        jsonData = json.decode(text);
      } on Object catch (_) {
        continue;
      }

      final recipe = _extractRecipe(
        jsonData: jsonData,
        document: document,
        recipeUrl: recipeUrl,
        localeName: localeName,
      );
      if (recipe != null) {
        return recipe;
      }
    }

    return null;
  }

  PreparedMealRecipeImport? _extractRecipe({
    required dynamic jsonData,
    required Document document,
    required String recipeUrl,
    String? localeName,
  }) {
    if (jsonData == null) {
      return null;
    }

    final graphById = <String, Map<String, dynamic>>{};
    Map<String, dynamic>? recipeMap;

    void indexNode(dynamic node) {
      if (node is Map<String, dynamic>) {
        final id = node['@id']?.toString();
        if (id != null) {
          graphById[id] = node;
        }
        if (_isRecipeType(node['@type'])) {
          recipeMap ??= node;
        }
      }
    }

    if (jsonData is Map<String, dynamic>) {
      if (jsonData['@graph'] is List) {
        (jsonData['@graph'] as List).forEach(indexNode);
      } else {
        indexNode(jsonData);
        final mainEntity = jsonData['mainEntity'];
        if (recipeMap == null && mainEntity is Map<String, dynamic>) {
          indexNode(mainEntity);
        }
      }
    } else if (jsonData is List) {
      jsonData.forEach(indexNode);
    }

    final resolved = recipeMap;
    if (resolved == null) {
      return null;
    }

    final rawTitle = _extractTitle(resolved, document);
    final rawImageUrl = _extractImageUrl(
          resolved['image'],
          graphById: graphById,
        ) ??
        _extractImageUrl(
          resolved['thumbnailUrl'],
          graphById: graphById,
        );

    final servings = _extractServings(resolved['recipeYield']);
    final ingredients = _extractIngredients(
      resolved['recipeIngredient'],
      localeName: localeName,
    );
    final instructions = _extractInstructions(
      resolved['recipeInstructions'],
    );

    return PreparedMealRecipeImport(
      recipeUrl: recipeUrl,
      imageUrl: formatter.normalizeRecipeImageUrl(rawImageUrl),
      title: rawTitle,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions,
      instructionsPreview: instructions.take(3).toList(growable: false),
    );
  }

  static bool _isRecipeType(dynamic type) {
    return switch (type) {
      final String s => s.trim().toLowerCase().endsWith('recipe'),
      final List<dynamic> list => list.any(_isRecipeType),
      _ => false,
    };
  }

  static String _extractTitle(
    Map<String, dynamic> recipeMap,
    Document document,
  ) {
    final name = recipeMap['name'] ?? recipeMap['headline'];
    if (name is String) {
      final cleaned = _cleanHtml(name);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    final ogTitle = document
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    if (ogTitle != null) {
      final cleaned = _cleanHtml(ogTitle);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    final docTitle = document.querySelector('title')?.text;
    if (docTitle != null) {
      final cleaned = _cleanHtml(docTitle);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    return 'Rezept';
  }

  static String? _extractImageUrl(
    dynamic raw, {
    Map<String, Map<String, dynamic>> graphById = const {},
  }) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }
    if (raw is List) {
      for (final item in raw) {
        final url = _extractImageUrl(item, graphById: graphById);
        if (url != null) {
          return url;
        }
      }
      return null;
    }
    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);

      for (final key in const [
        'url',
        'contentUrl',
        'thumbnailUrl',
        'thumbnail',
        'src',
        '16x9',
        '4x3',
        '1x1',
        'large',
        'medium',
        'regular',
      ]) {
        final url = _extractImageUrl(map[key], graphById: graphById);
        if (url != null) {
          return url;
        }
      }

      final id = map['@id']?.toString();
      if (id != null && graphById.containsKey(id) && graphById[id] != map) {
        final url = _extractImageUrl(graphById[id], graphById: graphById);
        if (url != null) {
          return url;
        }
      }

      for (final val in map.values.whereType<String>()) {
        final trimmed = val.trim();
        if (trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.startsWith('//')) {
          return trimmed;
        }
      }
    }
    return null;
  }

  static int _extractServings(dynamic yieldData) {
    if (yieldData is int && yieldData > 0) {
      return yieldData;
    }
    if (yieldData is num && yieldData > 0) {
      return yieldData.round();
    }
    if (yieldData is List) {
      for (final item in yieldData) {
        final parsed = _extractServings(item);
        if (parsed > 0) {
          return parsed;
        }
      }
    }
    if (yieldData is String) {
      final match = RegExp(r'\d+').firstMatch(yieldData);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 1;
      }
    }
    return 1;
  }

  List<String> _extractIngredients(
    dynamic raw, {
    String? localeName,
  }) {
    final result = <String>[];
    if (raw == null) {
      return result;
    }

    void add(String text) {
      final cleaned = _cleanHtml(text);
      if (cleaned.isEmpty) {
        return;
      }
      try {
        final formatted = formatter.formatIngredientLine(
          Ingredient.fromIngredientString(cleaned),
          localeName: localeName,
        );
        if (formatted.isNotEmpty) {
          result.add(formatted);
          return;
        }
      } on Object catch (_) {}
      result.add(cleaned);
    }

    if (raw is String) {
      raw.split(RegExp(r'[\r\n]+')).forEach(add);
    } else if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          final text = item['text'] ?? item['name'] ?? item['original'];
          if (text is String) {
            add(text);
          }
        }
      }
    }

    return result;
  }

  static List<String> _extractInstructions(dynamic raw) {
    final steps = <String>[];
    if (raw == null) {
      return steps;
    }

    void collect(dynamic item) {
      if (item == null) {
        return;
      }
      if (item is String) {
        item
            .split(RegExp(r'[\r\n]+'))
            .map(_cleanHtml)
            .where((line) => line.isNotEmpty)
            .forEach(steps.add);
      } else if (item is List) {
        item.forEach(collect);
      } else if (item is Map) {
        if (item.containsKey('itemListElement')) {
          collect(item['itemListElement']);
        } else {
          final text = item['text'] ?? item['name'] ?? item['description'];
          if (text is String) {
            final cleaned = _cleanHtml(text);
            if (cleaned.isNotEmpty) {
              steps.add(cleaned);
            }
          } else if (text != null) {
            collect(text);
          }
        }
      }
    }

    collect(raw);
    return steps;
  }

  static String _cleanHtml(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    try {
      final fragment = html_parser.parseFragment(trimmed);
      final text = fragment.text;
      if (text != null) {
        return text.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    } on Object catch (_) {}
    return trimmed
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
