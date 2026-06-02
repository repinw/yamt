import 'package:flutter/foundation.dart';

/// Parsed AI Chef recipe response before it is converted to a meal template.
@immutable
class AiChefRecipeDraft {
  /// Creates parsed AI Chef recipe response data.
  const AiChefRecipeDraft({
    required this.name,
    required this.portions,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.instructions,
    this.imagePrompt,
  });

  /// Recipe name.
  final String name;

  /// Total generated portions.
  final int portions;

  /// Total calories.
  final double kcal;

  /// Total protein in grams.
  final double protein;

  /// Total carbohydrates in grams.
  final double carbs;

  /// Total fat in grams.
  final double fat;

  /// Ingredient rows for the recipe template.
  final List<String> ingredients;

  /// Instruction rows for the recipe template.
  final List<String> instructions;

  /// Optional prompt for cover image generation.
  final String? imagePrompt;
}
