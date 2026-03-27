import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

import '../support/fake_calories_repositories.dart';

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required double totalKcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  test('calorieWeekOverview aggregates rolling seven-day totals', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final fourDaysAgo = today.subtract(const Duration(days: 4));
    final eightDaysAgo = today.subtract(const Duration(days: 8));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'today',
          loggedAt: today.add(const Duration(hours: 8)),
          totalKcal: 600,
        ),
        _entry(
          'four-days-ago',
          loggedAt: fourDaysAgo.add(const Duration(hours: 12)),
          totalKcal: 400,
        ),
        _entry(
          'outside-window',
          loggedAt: eightDaysAgo.add(const Duration(hours: 12)),
          totalKcal: 900,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings(
        dailyKcalGoal: 2000,
        updatedAt: today,
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);
    final overview = await container.read(calorieWeekOverviewProvider.future);

    expect(overview.days, hasLength(diaryVisibleDayCount));
    expect(overview.days.last.date, today);
    expect(overview.days.first.date, today.subtract(const Duration(days: 6)));
    expect(overview.totalConsumedKcal, 1000);
    expect(overview.totalGoalKcal, 14000);
    expect(overview.remainingKcal, 13000);
  });
}
