import 'package:flutter/widgets.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';

/// Stable keys for diary meal section tests.
abstract final class DiaryMealsSectionKeys {
  /// Group key for a logged meal type.
  static Key mealGroup(MealType mealType) {
    return ValueKey<String>('diary-meal-group-${mealType.jsonValue}');
  }

  /// Row key for a logged entry.
  static Key entryTile(String entryId) {
    return ValueKey<String>('diary-meal-entry-$entryId');
  }

  /// Button key for a quick-eat source.
  static Key quickEatSource(DiaryQuickEatSource source) {
    return ValueKey<String>('diary-quick-eat-source-${source.name}');
  }

  /// Hint shown on a day without logged food.
  static const emptyState = ValueKey<String>('diary-meals-empty-state');

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-meals-retry-button');
}
