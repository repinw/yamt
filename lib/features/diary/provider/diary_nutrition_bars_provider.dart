import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_macros.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';

/// Data for the diary nutrition bars.
class DiaryNutritionBarsData {
  /// Creates diary nutrition bars data.
  const DiaryNutritionBarsData({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.goals,
  });

  /// Consumed carbs in grams.
  final double carbs;

  /// Consumed protein in grams.
  final double protein;

  /// Consumed fat in grams.
  final double fat;

  /// Target macro grams.
  final CaloriesSummaryMacroGoals goals;
}

/// Provides real macro totals and targets for one diary day.
final FutureProviderFamily<DiaryNutritionBarsData, DateTime>
diaryNutritionBarsDataProvider = FutureProvider.autoDispose
    .family<DiaryNutritionBarsData, DateTime>((
      ref,
      day,
    ) async {
      final normalizedDay = normalizeDiaryDay(day);
      final resolvedGoalFuture = ref.watch(
        resolvedCalorieGoalForDayProvider(normalizedDay).future,
      );
      final entriesFuture = ref.watch(
        diaryEntriesForDayProvider(normalizedDay).future,
      );
      final resolvedGoal = await resolvedGoalFuture;
      final entries = await entriesFuture;

      var carbs = 0.0;
      var protein = 0.0;
      var fat = 0.0;
      for (final entry in entries) {
        carbs += entry.totalCarbs;
        protein += entry.totalProtein;
        fat += entry.totalFat;
      }

      return DiaryNutritionBarsData(
        carbs: carbs,
        protein: protein,
        fat: fat,
        goals: CaloriesSummaryMacroGoals.fromGoalKcal(
          resolvedGoal.goalKcal,
        ),
      );
    });
