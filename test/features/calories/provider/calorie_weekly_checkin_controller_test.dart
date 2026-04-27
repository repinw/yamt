import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test(
    'applyWeeklyCheckIn stores learned cache without changing active goal',
    () async {
      final goalStart = DateTime(2026, 4, 8);
      final dueDate = DateTime(2026, 4, 15);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2426.875,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.male,
            weightKg: 84,
            heightCm: 172,
            ageYears: 31,
            activityLevel: 1.375,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          effectiveDate: goalStart,
          source: CalorieGoalSource.calculator,
        ),
      );
      addTearDown(settingsRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .applyWeeklyCheckIn(
            _weeklyCheckInViewModel(
              pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
                windowStartDate: goalStart,
                windowEndDate: DateTime(2026, 4, 14),
                dueDate: dueDate,
                dismissedAt: DateTime(2026, 4, 27, 10),
              ),
            ),
          );

      expect(saved, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(settings.goalKcalForDay(DateTime(2026, 4, 14)), 2426.875);
      expect(settings.goalKcalForDay(dueDate), 2426.875);
      expect(settings.latestGoalEntry?.effectiveDate, goalStart);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.pendingWeeklyCheckIn?.isDismissed, isTrue);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2665.82);
      final snapshot = settings.latestLearnedTdeeEntry?.weeklyCheckInSnapshot;
      expect(snapshot?.windowStartDate, goalStart);
      expect(snapshot?.windowEndDate, DateTime(2026, 4, 14));
    },
  );

  test(
    'syncLearnedTdeeCache stores learned cache without dismissing hint',
    () async {
      final goalStart = DateTime(2026, 4, 8);
      final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: DateTime(2026, 4, 15),
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2426.875,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.male,
            weightKg: 84,
            heightCm: 172,
            ageYears: 31,
            activityLevel: 1.375,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          effectiveDate: goalStart,
          source: CalorieGoalSource.calculator,
        ).copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
      );
      addTearDown(settingsRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .syncLearnedTdeeCache(
            _weeklyCheckInViewModel(
              pendingWeeklyCheckIn: pendingWeeklyCheckIn,
            ),
          );

      expect(saved, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(
        settings.pendingWeeklyCheckIn?.windowKey,
        pendingWeeklyCheckIn.windowKey,
      );
      expect(settings.pendingWeeklyCheckIn?.isDismissed, isFalse);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2665.82);
    },
  );
}

CalorieWeeklyCheckInViewModel _weeklyCheckInViewModel({
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  return CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: false,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: const CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: -0.10893,
      averageIntakeKcal: 2460.85,
      measuredTrueTdeeKcal: 3223.35,
      calculatedTrueTdeeKcal: 2665.82,
      newGoalKcal: 2626.875,
      lastWeekAverageActiveKcal: 300,
      todayActiveKcal: 8,
      activityDeltaKcal: 0,
      dynamicGoalTodayKcal: 2626.875,
    ),
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}
