import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

/// Builds diary meal sections from calorie entries and plans. The meal
/// totals add the plans only when [countsPlans].
List<DiaryMealSection> buildDiaryDashboardMealSections(
  List<CalorieEntry> entries, {
  required List<CalorieEntry> plannedEntries,
  required bool countsPlans,
}) {
  List<DiaryMealEntry> rowsOf(Iterable<CalorieEntry> source, MealType type) =>
      List<DiaryMealEntry>.unmodifiable(
        source.where((entry) => entry.mealType == type).map(_mealEntryFrom),
      );

  return MealType.sectionOrder
      .map((mealType) {
        final rows = rowsOf(entries, mealType);
        final plans = rowsOf(plannedEntries, mealType);
        return DiaryMealSection(
          mealType: mealType,
          entries: rows,
          plannedEntries: plans,
          countsPlans: countsPlans,
          totalKcal: [
            ...rows,
            if (countsPlans) ...plans,
          ].fold(0, (sum, entry) => sum + entry.totalKcal),
        );
      })
      .toList(growable: false);
}

/// Builds diary nutrition bars from calorie entries.
DiaryNutritionBarsData buildDiaryDashboardNutritionBars(
  List<CalorieEntry> entries,
  double goalKcal, {
  DiaryMacroTargets? macroTargets,
}) {
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
    goals: macroTargets ?? DiaryMacroTargets.fromGoalKcal(goalKcal),
  );
}

/// [day] with [plannedEntries] added, for a day whose plans count.
CalorieWeekDayOverview addDiaryPlansToDay(
  CalorieWeekDayOverview day,
  List<CalorieEntry> plannedEntries,
) => plannedEntries.isEmpty
    ? day
    : CalorieWeekDayOverview(
        date: day.date,
        totalKcal: plannedEntries.fold(
          day.totalKcal,
          (sum, entry) => sum + entry.totalKcal,
        ),
        goalKcal: day.goalKcal,
        baseGoalKcal: day.baseGoalKcal,
        entryCount: day.entryCount + plannedEntries.length,
        isPauseDay: day.isPauseDay,
      );

DiaryMealEntry _mealEntryFrom(CalorieEntry entry) {
  // A quick entry counts as 100 g of itself; the row shows no amount for it.
  final hasAmount = !entry.isQuickEntry;
  return DiaryMealEntry(
    id: entry.id,
    mealType: entry.mealType,
    name: entry.name,
    imageUrl: entry.imageUrl,
    imageAssetId: entry.imageAssetId,
    totalKcal: entry.totalKcal,
    totalProtein: entry.totalProtein,
    totalCarbs: entry.totalCarbs,
    totalFat: entry.totalFat,
    consumedAmount: hasAmount ? entry.consumedAmount : null,
    consumedUnit: hasAmount ? entry.consumedUnit : null,
    bundleConsumedPortions: entry.bundleConsumedPortions,
    bundleTotalPortions: entry.bundleTotalPortions,
    combinedFoods: entry.isCombined ? entry.bundleComponents : null,
  );
}
