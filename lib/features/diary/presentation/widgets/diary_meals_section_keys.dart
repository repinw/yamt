import 'package:flutter/widgets.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// Stable keys for diary meal section tests.
abstract final class DiaryMealsSectionKeys {
  /// Card key for a meal section.
  static Key mealCard(MealType mealType) {
    return ValueKey<String>('diary-meal-card-${mealType.jsonValue}');
  }

  /// Collapsed empty-state key for a meal section.
  static Key collapsedEmpty(MealType mealType) {
    return ValueKey<String>(
      'diary-meal-collapsed-empty-${mealType.jsonValue}',
    );
  }

  /// Expanded empty-state key for a meal section.
  static Key expandedEmpty(MealType mealType) {
    return ValueKey<String>(
      'diary-meal-expanded-empty-${mealType.jsonValue}',
    );
  }

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-meals-retry-button');
}
