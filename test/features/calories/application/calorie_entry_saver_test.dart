import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_goal_weekly_check_in_snapshot.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('an entry on a checked-in day marks that check-in stale', () async {
    final checkedIn = CalorieGoalHistoryEntry(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime.utc(2026, 3, 15),
      changedAt: DateTime.utc(2026, 3, 15),
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime.utc(2026, 3, 8),
        windowEndDate: DateTime.utc(2026, 3, 14),
        trendWeightChangePerDay: 0,
        lowConfidence: false,
      ),
    );
    final settings = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().copyWith(
        goalHistory: [checkedIn],
      ),
    );
    final log = FakeCalorieLogRepository();
    addTearDown(log.dispose);
    addTearDown(settings.dispose);
    final now = DateTime.utc(2026, 3, 16);
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(log),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(calorieEntrySaverProvider, (_, _) {});
    addTearDown(subscription.close);

    final day = DateTime.utc(2026, 3, 10, 12);
    final saved = await subscription.read()(
      CalorieEntry.create(
        id: 'entry-1',
        userId: 'user-1',
        name: 'Milk',
        mealType: MealType.lunch,
        consumedAmount: 200,
        consumedUnit: ConsumedUnit.milliliters,
        per100Kcal: 60,
        per100Protein: 3.2,
        per100Carbs: 4.8,
        per100Fat: 1.5,
        loggedAt: day,
        createdAt: day,
        updatedAt: day,
      ),
      isNewEntry: true,
    );
    await pumpEventQueue();

    expect(saved, isTrue);
    final snapshot = (await settings.readSettings())
        .goalHistory
        .single
        .weeklyCheckInSnapshot;
    expect(snapshot?.isInputDirty, isTrue);
  });
}
