import 'dart:convert';

import 'package:yamt/features/ai_chef/data/ai_chef_recipe_draft.dart';

/// Parses Firebase AI Chef template responses.
class AiChefRecipeResponseParser {
  /// Creates parser.
  const AiChefRecipeResponseParser();

  /// Parses a raw model response into an AI Chef recipe draft.
  AiChefRecipeDraft? parse(String responseText) {
    try {
      final cleanedText = _extractJsonPayload(responseText);
      final decoded = jsonDecode(cleanedText);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final ingredients = _readStringList(decoded['ingredients']);
      final instructions = _readStringList(decoded['instructions']);
      if (ingredients.isEmpty || instructions.isEmpty) {
        return null;
      }

      return AiChefRecipeDraft(
        name: decoded['name'] as String? ?? 'AI Recipe',
        portions: (decoded['portions'] as num?)?.toInt() ?? 2,
        kcal: (decoded['kcal'] as num?)?.toDouble() ?? 0.0,
        protein: (decoded['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (decoded['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (decoded['fat'] as num?)?.toDouble() ?? 0.0,
        ingredients: ingredients,
        instructions: instructions,
        imagePrompt: decoded['image_prompt'] as String?,
      );
    } on Object {
      return null;
    }
  }

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.map((item) => item.toString()).toList();
  }

  String _extractJsonPayload(String text) {
    var trimmed = text.trim();
    final fencedJson = RegExp(
      r'```(?:json)?\s*(.*?)```',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(trimmed);
    if (fencedJson != null) {
      return fencedJson.group(1)!.trim();
    }

    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      trimmed = trimmed.substring(jsonStart, jsonEnd + 1);
    }
    return trimmed;
  }
}
