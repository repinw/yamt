import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

void main() {
  group('DiaryMealSection macro totals', () {
    test('computes totalProtein, totalCarbs, and totalFat from entries', () {
      final section = DiaryMealSection(
        mealType: MealType.lunch,
        totalKcal: 650,
        plannedEntries: const [],
        countsPlans: false,
        entries: [
          const DiaryMealEntry(
            id: 'chicken',
            mealType: MealType.lunch,
            name: 'Chicken Breast',
            totalKcal: 250,
            totalProtein: 45.5,
            totalCarbs: 0,
            totalFat: 5.2,
          ),
          const DiaryMealEntry(
            id: 'rice',
            mealType: MealType.lunch,
            name: 'White Rice',
            totalKcal: 400,
            totalProtein: 8.2,
            totalCarbs: 85.3,
            totalFat: 1.5,
          ),
        ],
      );

      expect(section.totalProtein, closeTo(53.7, 0.001));
      expect(section.totalCarbs, closeTo(85.3, 0.001));
      expect(section.totalFat, closeTo(6.7, 0.001));
    });

    test('returns 0 when section has no entries', () {
      final section = DiaryMealSection(
        mealType: MealType.dinner,
        totalKcal: 0,
        entries: [],
        plannedEntries: const [],
        countsPlans: false,
      );

      expect(section.totalProtein, 0);
      expect(section.totalCarbs, 0);
      expect(section.totalFat, 0);
    });
  });

  group('DiaryMealSection heading total', () {
    DiaryMealEntry food(String id, double kcal, {bool pending = false}) =>
        DiaryMealEntry(
          id: id,
          mealType: MealType.lunch,
          name: id,
          totalKcal: kcal,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          nutritionPending: pending,
        );
    DiaryMealSection section({required bool countsPlans}) => DiaryMealSection(
      mealType: MealType.lunch,
      totalKcal: countsPlans ? 650 : 400,
      entries: [food('rice', 400)],
      plannedEntries: [food('plan', 250), food('reminder', 0, pending: true)],
      countsPlans: countsPlans,
    );

    test('today adds the plans only when the head counts them', () {
      final today = section(countsPlans: false);

      expect(today.headingTotal(withOpenPlans: false), (kcal: 400, rows: 1));
      expect(today.headingTotal(withOpenPlans: true), (kcal: 650, rows: 2));
    });

    test('a planned day counts its plans once, reminders not as rows', () {
      final planned = section(countsPlans: true);

      expect(planned.headingTotal(withOpenPlans: false), (kcal: 650, rows: 2));
      expect(planned.headingTotal(withOpenPlans: true), (kcal: 650, rows: 2));
    });
  });
}
