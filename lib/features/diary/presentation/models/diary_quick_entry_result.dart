import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// How the quick entry page closed, other than by the close button.
sealed class DiaryQuickEntryResult {
  const new();
}

/// The typed values were saved as [entry].
class DiaryQuickEntrySaved extends DiaryQuickEntryResult {
  /// Creates the result.
  const new(this.entry, {required this.isPlan});

  /// The saved quick entry.
  final CalorieEntry entry;

  /// Whether [entry] was saved as a plan.
  final bool isPlan;
}

/// The user chose the AI estimate instead, for the picked day and meal.
class DiaryQuickEntryAiRequested extends DiaryQuickEntryResult {
  /// Creates the result.
  const new({required this.loggedAt, required this.mealType});

  /// When the food is logged.
  final DateTime loggedAt;

  /// Meal the food is logged to.
  final MealType mealType;
}
