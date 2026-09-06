import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

void main() {
  group('buildDiaryDashboardMealSections', () {
    test('maps calorie entries into ordered meal sections and sums kcal', () {
      final selectedDay = DateTime(2026, 4, 27, 18);
      final normalizedDay = normalizeDiaryDay(selectedDay);

      final entries = <CalorieEntry>[
        _entry(
          id: 'breakfast',
          day: normalizedDay,
          mealType: MealType.breakfast,
          name: 'Oats',
          totalKcal: 320,
          totalProtein: 18,
          totalCarbs: 44,
          totalFat: 8,
          imageUrl: 'https://example.com/oats.png',
          imageAssetId: 'asset-oats',
          consumedAmount: 150,
          consumedUnit: ConsumedUnit.milliliters,
          bundleConsumedPortions: 1,
          bundleTotalPortions: 2,
        ),
        _entry(
          id: 'lunch-1',
          day: normalizedDay,
          mealType: MealType.lunch,
          name: 'Rice',
          totalKcal: 420,
          totalProtein: 8,
          totalCarbs: 90,
          totalFat: 2,
        ),
        _entry(
          id: 'lunch-2',
          day: normalizedDay,
          mealType: MealType.lunch,
          name: 'Chicken',
          totalKcal: 260,
          totalProtein: 50,
          totalFat: 6,
        ),
      ];

      final sections = buildDiaryDashboardMealSections(entries);

      expect(
        sections.map((section) => section.mealType),
        MealType.sectionOrder,
      );
      expect(sections[0].totalKcal, 320);
      expect(sections[0].entries.single.id, 'breakfast');
      expect(sections[0].entries.single.name, 'Oats');
      expect(sections[0].entries.single.totalProtein, 18);
      expect(sections[0].entries.single.totalCarbs, 44);
      expect(sections[0].entries.single.totalFat, 8);
      expect(
        sections[0].entries.single.imageUrl,
        'https://example.com/oats.png',
      );
      expect(sections[0].entries.single.imageAssetId, 'asset-oats');
      expect(sections[0].entries.single.consumedAmount, 150);
      expect(sections[0].entries.single.consumedUnit, ConsumedUnit.milliliters);
      expect(sections[0].entries.single.bundleConsumedPortions, 1);
      expect(sections[0].entries.single.bundleTotalPortions, 2);

      expect(sections[1].totalKcal, 680);
      expect(sections[1].entries.map((entry) => entry.id), [
        'lunch-1',
        'lunch-2',
      ]);

      expect(sections[2].entries, isEmpty);
      expect(sections[2].totalKcal, 0);

      expect(sections[3].entries, isEmpty);
      expect(sections[3].totalKcal, 0);

      expect(
        () => (sections[0].entries as dynamic).add(sections[0].entries.first),
        throwsUnsupportedError,
      );
    });
  });

  group('buildDiaryDashboardNutritionBars', () {
    test('sums macros from entries and derives macro targets from goal', () {
      final selectedDay = DateTime(2026, 4, 27, 18);
      final normalizedDay = normalizeDiaryDay(selectedDay);

      final entries = <CalorieEntry>[
        _entry(
          id: 'breakfast',
          day: normalizedDay,
          mealType: MealType.breakfast,
          name: 'Breakfast',
          totalKcal: 348,
          totalCarbs: 36,
          totalProtein: 24,
          totalFat: 12,
        ),
        _entry(
          id: 'lunch',
          day: normalizedDay,
          mealType: MealType.lunch,
          name: 'Lunch',
          totalKcal: 321,
          totalCarbs: 18,
          totalProtein: 42,
          totalFat: 9,
        ),
      ];

      final data = buildDiaryDashboardNutritionBars(entries, 2400);

      expect(data.carbs, 54);
      expect(data.protein, 66);
      expect(data.fat, 21);
      expect(data.goals.carbs, 270);
      expect(data.goals.protein, 150);
      expect(data.goals.fat, 80);
    });

    test('clamps negative calorie goals to zero macro targets', () {
      final data = buildDiaryDashboardNutritionBars(const [], -838);

      expect(data.goals.carbs, 0);
      expect(data.goals.protein, 0);
      expect(data.goals.fat, 0);
    });

    test('uses custom macro targets when provided', () {
      const customTargets = DiaryMacroTargets(
        carbs: 200,
        protein: 180,
        fat: 60,
      );

      final data = buildDiaryDashboardNutritionBars(
        const [],
        2400,
        macroTargets: customTargets,
      );

      expect(data.goals, customTargets);
    });
  });
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required String name,
  required double totalKcal,
  double totalProtein = 0,
  double totalCarbs = 0,
  double totalFat = 0,
  String? imageUrl,
  String? imageAssetId,
  double consumedAmount = 100,
  ConsumedUnit consumedUnit = ConsumedUnit.grams,
  int? bundleConsumedPortions,
  int? bundleTotalPortions,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: name,
    mealType: mealType,
    consumedAmount: consumedAmount,
    consumedUnit: consumedUnit,
    per100Kcal: totalKcal,
    per100Protein: totalProtein,
    per100Carbs: totalCarbs,
    per100Fat: totalFat,
    totalKcal: totalKcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
    imageUrl: imageUrl,
    imageAssetId: imageAssetId,
    bundleConsumedPortions: bundleConsumedPortions,
    bundleTotalPortions: bundleTotalPortions,
  );
}
