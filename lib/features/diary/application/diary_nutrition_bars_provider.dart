import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

part 'diary_nutrition_bars_provider.g.dart';

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
  final DiaryMacroTargets goals;
}

/// Provides real macro totals and targets for one diary day.
@riverpod
Future<DiaryNutritionBarsData> diaryNutritionBarsData(
  Ref ref,
  DateTime day,
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
    goals: DiaryMacroTargets.fromGoalKcal(
      resolvedGoal.goalKcal,
    ),
  );
}

/// Actions needed by diary nutrition bar widgets.
@riverpod
DiaryNutritionBarsActions diaryNutritionBarsActions(Ref ref) {
  return DiaryNutritionBarsActions(
    refreshNutritionBars: (day) {
      if (!ref.mounted) {
        return;
      }
      final normalizedDay = normalizeDiaryDay(day);
      ref
        ..invalidate(diaryEntriesForDayProvider(normalizedDay))
        ..invalidate(resolvedCalorieGoalForDayProvider(normalizedDay))
        ..invalidate(diaryNutritionBarsDataProvider(normalizedDay));
    },
  );
}

/// Operations that bridge diary nutrition UI to application state.
class DiaryNutritionBarsActions {
  /// Creates diary nutrition bar actions.
  const DiaryNutritionBarsActions({
    required void Function(DateTime day) refreshNutritionBars,
  }) : _refreshNutritionBars = refreshNutritionBars;

  final void Function(DateTime day) _refreshNutritionBars;

  /// Refreshes diary nutrition totals and their goal source.
  void refreshNutritionBars(DateTime day) {
    _refreshNutritionBars(day);
  }
}
