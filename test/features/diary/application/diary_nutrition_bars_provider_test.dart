import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';

void main() {
  test(
    'sums macros from entries and derives macro targets from goal',
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
                totalCarbs: 36,
                totalProtein: 24,
                totalFat: 12,
              ),
              _entry(
                id: 'lunch',
                day: normalizedDay,
                totalCarbs: 18,
                totalProtein: 42,
                totalFat: 9,
              ),
            ],
          ),
          resolvedCalorieGoalForDayProvider(
            normalizedDay,
          ).overrideWith((ref) async => _resolvedGoal(normalizedDay, 2400)),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(
        diaryNutritionBarsDataProvider(selectedDay).future,
      );

      expect(data.carbs, 54);
      expect(data.protein, 66);
      expect(data.fat, 21);
      expect(data.goals.carbs, 270);
      expect(data.goals.protein, 150);
      expect(data.goals.fat, 80);
    },
  );
}

ResolvedCalorieGoalData _resolvedGoal(DateTime day, double goalKcal) {
  return ResolvedCalorieGoalData(
    day: day,
    storedGoalKcal: goalKcal,
    goalKcal: goalKcal,
    activityDeltaKcal: 0,
    lastWeekAverageActiveKcal: 0,
    todayActiveKcal: 0,
    usedLearnedTdee: false,
    usesPreLearningActivityBonus: false,
    wasClampedToMinimum: false,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required double totalCarbs,
  required double totalProtein,
  required double totalFat,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: totalProtein,
    per100Carbs: totalCarbs,
    per100Fat: totalFat,
    totalKcal: 100,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
