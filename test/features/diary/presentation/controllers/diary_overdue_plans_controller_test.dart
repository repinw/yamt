import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_overdue_plans_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

void main() {
  final today = DateTime(2026, 10, 7);

  CalorieEntry plan(String id, DateTime day) => buildQuickCalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: MealType.dinner,
    loggedAt: day.add(const Duration(hours: 19)),
    now: day,
    kcal: 500,
  );

  Future<ProviderContainer> setUp(
    List<CalorieEntry> plans,
    MemoryAppPreferences preferences,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        calorieSettingsRepositoryProvider.overrideWithValue(
          FakeCalorieSettingsRepository(
            initialSettings: const CalorieGoalSettings.empty().copyWith(
              goalHistory: [
                CalorieGoalHistoryEntry(
                  dailyKcalGoal: 2000,
                  calculatorProfile: null,
                  effectiveDate: DateTime(2026, 9),
                  changedAt: DateTime(2026, 9),
                ),
              ],
            ),
          ),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(plans: plans),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(diaryOverduePlansControllerProvider(today), (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('names the days of the last week with plans left', () async {
    final container = await setUp([
      plan('long ago', DateTime(2026, 9, 20)),
      plan('monday', DateTime(2026, 10, 5)),
      plan('yesterday', DateTime(2026, 10, 6)),
      plan('today', today),
    ], MemoryAppPreferences());

    expect(container.read(diaryOverduePlansControllerProvider(today)), [
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 6),
    ]);
  });

  test('closing hides the hint until a later day has plans left', () async {
    final preferences = MemoryAppPreferences();
    final container = await setUp([
      plan('monday', DateTime(2026, 10, 5)),
    ], preferences);
    final provider = diaryOverduePlansControllerProvider(today);

    await container.read(provider.notifier).dismiss();
    expect(container.read(provider), isNull);

    final tomorrow = DateTime(2026, 10, 8);
    final next = await setUp([
      plan('monday', DateTime(2026, 10, 5)),
      plan('wednesday', today),
    ], preferences);
    next.listen(diaryOverduePlansControllerProvider(tomorrow), (_, _) {});
    await pumpEventQueue();
    expect(next.read(diaryOverduePlansControllerProvider(tomorrow)), [
      DateTime(2026, 10, 5),
      today,
    ]);
  });
}
