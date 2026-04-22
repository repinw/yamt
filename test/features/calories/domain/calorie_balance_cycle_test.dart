import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  group('resolveCalorieBalanceCycleStartDate', () {
    test(
      'returns the active cycle anchor date when an active goal exists',
      () {
        final settings =
            CalorieGoalSettings.single(
              dailyKcalGoal: 2100,
              calculatorProfile: null,
              effectiveDate: DateTime(2026, 4, 1, 8),
            ).applyGoalChange(
              changedAt: DateTime(2026, 4, 8, 9),
              dailyKcalGoal: 2200,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
            );

        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: settings,
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 12),
        );

        expect(startDate, DateTime(2026, 4));
      },
    );

    test(
      'falls back to the normalized fallback start date when no goal exists',
      () {
        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: const CalorieGoalSettings.empty(),
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 18, 30),
        );

        expect(startDate, DateTime(2026, 4, 4));
      },
    );

    test(
      'uses the next goal start when the current day has no active goal yet',
      () {
        final settings = CalorieGoalSettings.single(
          dailyKcalGoal: 2300,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 12, 18),
        );

        final startDate = resolveCalorieBalanceCycleStartDate(
          settings: settings,
          day: DateTime(2026, 4, 10, 14),
          fallbackStartDate: DateTime(2026, 4, 4, 12),
        );

        expect(startDate, DateTime(2026, 4, 12));
      },
    );
  });
}
