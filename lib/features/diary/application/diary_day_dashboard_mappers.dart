import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

/// Builds diary meal sections from calorie entries.
List<DiaryMealSection> buildDiaryDashboardMealSections(
  List<CalorieEntry> entries,
) {
  final sectionEntries = <MealType, List<DiaryMealEntry>>{
    for (final mealType in MealType.sectionOrder) mealType: <DiaryMealEntry>[],
  };
  final sectionKcal = <MealType, double>{
    for (final mealType in MealType.sectionOrder) mealType: 0,
  };

  for (final entry in entries) {
    sectionEntries[entry.mealType]?.add(_mealEntryFrom(entry));
    sectionKcal[entry.mealType] =
        (sectionKcal[entry.mealType] ?? 0) + entry.totalKcal;
  }

  return MealType.sectionOrder
      .map((mealType) {
        return DiaryMealSection(
          mealType: mealType,
          entries: List<DiaryMealEntry>.unmodifiable(
            sectionEntries[mealType] ?? const <DiaryMealEntry>[],
          ),
          totalKcal: sectionKcal[mealType] ?? 0,
        );
      })
      .toList(growable: false);
}

/// Builds diary nutrition bars from calorie entries.
DiaryNutritionBarsData buildDiaryDashboardNutritionBars(
  List<CalorieEntry> entries,
  double goalKcal,
) {
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
    goals: DiaryMacroTargets.fromGoalKcal(goalKcal),
  );
}

DiaryMealEntry _mealEntryFrom(CalorieEntry entry) {
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
  );
}
