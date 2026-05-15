import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

part 'diary_meal_sections_provider.g.dart';

/// Provides real meal sections for one diary day.
@riverpod
Future<List<DiaryMealSection>> diaryMealSections(
  Ref ref,
  DateTime day,
) async {
  final normalizedDay = normalizeDiaryDay(day);
  final entriesFuture = ref.watch(
    diaryEntriesForDayProvider(normalizedDay).future,
  );
  final entries = await entriesFuture;

  final sectionEntries = <MealType, List<DiaryMealEntry>>{
    for (final mealType in MealType.sectionOrder) mealType: <DiaryMealEntry>[],
  };
  final sectionKcal = <MealType, double>{
    for (final mealType in MealType.sectionOrder) mealType: 0,
  };

  for (final entry in entries) {
    sectionEntries[entry.mealType]?.add(_diaryMealEntryFrom(entry));
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

DiaryMealEntry _diaryMealEntryFrom(CalorieEntry entry) {
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
