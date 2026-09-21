import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('archive lists goals without the all-goals aggregate', () async {
    final settings =
        CalorieGoalSettings.single(
              dailyKcalGoal: 2000,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              effectiveDate: DateTime(2026, 6),
            )
            .markActiveGoalEnded(DateTime(2026, 6, 10), weightKg: 79)
            .applyGoalChange(
              changedAt: DateTime(2026, 6, 10),
              dailyKcalGoal: 2400,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              preserveSameDayGoalEntries: true,
            );
    final repository = FakeCalorieSettingsRepository(initialSettings: settings);
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(calorieGoalArchiveProvider, (_, _) {});

    final cycles = await container.read(calorieGoalArchiveProvider.future);

    expect(cycles, hasLength(2));
    expect(cycles.any((cycle) => cycle.isAllGoals), isFalse);
    expect(cycles.where((cycle) => cycle.isActive), hasLength(1));
    expect(cycles.last.endDate, DateTime(2026, 6, 10));
  });
}
