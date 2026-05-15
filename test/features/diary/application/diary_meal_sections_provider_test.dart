import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';

void main() {
  test(
    'maps calorie entries into ordered meal sections and sums kcal',
    () async {
      final selectedDay = DateTime(2026, 4, 27, 18);
      final normalizedDay = normalizeDiaryDay(selectedDay);
      final container = ProviderContainer(
        overrides: [
          diaryEntriesForDayProvider(normalizedDay).overrideWith(
            (ref) async => <CalorieEntry>[
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
              ),
              _entry(
                id: 'lunch-1',
                day: normalizedDay,
                mealType: MealType.lunch,
                name: 'Rice',
                totalKcal: 420,
              ),
              _entry(
                id: 'lunch-2',
                day: normalizedDay,
                mealType: MealType.lunch,
                name: 'Chicken',
                totalKcal: 260,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final sections = await container.read(
        diaryMealSectionsProvider(selectedDay).future,
      );

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
      expect(sections[1].totalKcal, 680);
      expect(sections[1].entries.map((entry) => entry.id), [
        'lunch-1',
        'lunch-2',
      ]);
      expect(sections[2].entries, isEmpty);
      expect(sections[2].totalKcal, 0);
      expect(sections[3].entries, isEmpty);
      expect(sections[3].totalKcal, 0);
    },
  );
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
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: name,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
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
  );
}
