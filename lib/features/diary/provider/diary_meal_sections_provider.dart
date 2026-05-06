import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';

/// Provides real meal sections for one diary day.
final FutureProviderFamily<List<CalorieMealSection>, DateTime>
diaryMealSectionsProvider = FutureProvider.autoDispose
    .family<List<CalorieMealSection>, DateTime>((
      ref,
      day,
    ) async {
      final normalizedDay = normalizeDiaryDay(day);
      final entriesFuture = ref.watch(
        diaryEntriesForDayProvider(normalizedDay).future,
      );
      final entries = await entriesFuture;

      final sectionEntries = <MealType, List<CalorieEntry>>{
        for (final mealType in MealType.sectionOrder)
          mealType: <CalorieEntry>[],
      };
      final sectionKcal = <MealType, double>{
        for (final mealType in MealType.sectionOrder) mealType: 0,
      };

      for (final entry in entries) {
        sectionEntries[entry.mealType]?.add(entry);
        sectionKcal[entry.mealType] =
            (sectionKcal[entry.mealType] ?? 0) + entry.totalKcal;
      }

      return MealType.sectionOrder
          .map((mealType) {
            return CalorieMealSection(
              mealType: mealType,
              entries: List<CalorieEntry>.unmodifiable(
                sectionEntries[mealType] ?? const <CalorieEntry>[],
              ),
              totalKcal: sectionKcal[mealType] ?? 0,
            );
          })
          .toList(growable: false);
    });
