import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

void main() {
  group('DiaryMealSection macro totals', () {
    test('computes totalProtein, totalCarbs, and totalFat from entries', () {
      const section = DiaryMealSection(
        mealType: MealType.lunch,
        totalKcal: 650,
        entries: [
          DiaryMealEntry(
            id: 'chicken',
            mealType: MealType.lunch,
            name: 'Chicken Breast',
            totalKcal: 250,
            totalProtein: 45.5,
            totalCarbs: 0,
            totalFat: 5.2,
          ),
          DiaryMealEntry(
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
      const section = DiaryMealSection(
        mealType: MealType.dinner,
        totalKcal: 0,
        entries: [],
      );

      expect(section.totalProtein, 0);
      expect(section.totalCarbs, 0);
      expect(section.totalFat, 0);
    });
  });
}
