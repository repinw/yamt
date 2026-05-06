import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/features/diary/provider/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/provider/diary_nutrition_bars_provider.dart';

import '../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('shares one entries fetch across diary day consumers', () async {
    final entriesCompleter = Completer<List<CalorieEntry>>();
    var readCount = 0;
    final repository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (day) {
        readCount += 1;
        expect(day, selectedDay);
        return entriesCompleter.future;
      };
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        resolvedCalorieGoalForDayProvider(
          selectedDay,
        ).overrideWith((ref) => _resolvedGoal(selectedDay)),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final entriesSubscription = container.listen(
      diaryEntriesForDayProvider(selectedDay),
      (_, _) {},
    );
    final mealsSubscription = container.listen(
      diaryMealSectionsProvider(selectedDay),
      (_, _) {},
    );
    final nutritionSubscription = container.listen(
      diaryNutritionBarsDataProvider(selectedDay),
      (_, _) {},
    );
    addTearDown(entriesSubscription.close);
    addTearDown(mealsSubscription.close);
    addTearDown(nutritionSubscription.close);

    await container.pump();
    expect(readCount, 1);

    entriesCompleter.complete([
      _entry(id: 'breakfast', day: selectedDay, mealType: MealType.breakfast),
    ]);

    final entries = await container.read(
      diaryEntriesForDayProvider(selectedDay).future,
    );
    final sections = await container.read(
      diaryMealSectionsProvider(selectedDay).future,
    );
    final nutrition = await container.read(
      diaryNutritionBarsDataProvider(selectedDay).future,
    );

    expect(entries, hasLength(1));
    expect(sections.first.totalKcal, 100);
    expect(nutrition.carbs, 10);
    expect(readCount, 1);
  });

  test('autoDispose clears entries cache after last listener closes', () async {
    var readCount = 0;
    final repository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (_) async {
        readCount += 1;
        return const <CalorieEntry>[];
      };
    final container = ProviderContainer(
      overrides: [calorieLogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final provider = diaryEntriesForDayProvider(selectedDay);
    final subscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(readCount, 1);

    subscription.close();
    await container.pump();

    final nextSubscription = container.listen(provider, (_, _) {});
    addTearDown(nextSubscription.close);
    await container.read(provider.future);
    expect(readCount, 2);
  });
}

ResolvedCalorieGoalData _resolvedGoal(DateTime day) {
  return ResolvedCalorieGoalData(
    day: day,
    storedGoalKcal: 2400,
    goalKcal: 2400,
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
  required MealType mealType,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 5,
    per100Carbs: 10,
    per100Fat: 2,
    totalKcal: 100,
    totalProtein: 5,
    totalCarbs: 10,
    totalFat: 2,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
