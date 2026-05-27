import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart'
    as checkin_provider;
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show diaryWeeklyCheckInActionsProvider, diaryWeeklyCheckInDataProvider;

import '../../calories/support/fake_calories_repositories.dart';

void main() {
  test(
    'showWeeklyCheckInAgain clears dismissal and invalidates check-in data',
    () async {
      final dismissedPending = _pendingWeeklyCheckIn().copyWith(
        dismissedAt: DateTime(2026, 4, 15, 10),
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: _settingsWithGoal().copyWithPendingWeeklyCheckIn(
          dismissedPending,
        ),
      );
      var checkInDataBuildCount = 0;
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          checkin_provider.calorieWeeklyCheckInDataProvider.overrideWith((ref) {
            checkInDataBuildCount += 1;
            return _weeklyCheckInData(dismissedPending);
          }),
        ],
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(container.dispose);
      final checkInSubscription = container.listen(
        checkin_provider.calorieWeeklyCheckInDataProvider,
        (_, _) {},
      );
      final diarySubscription = container.listen(
        diaryWeeklyCheckInDataProvider,
        (_, _) {},
      );
      addTearDown(checkInSubscription.close);
      addTearDown(diarySubscription.close);
      await container.read(
        checkin_provider.calorieWeeklyCheckInDataProvider.future,
      );
      await container.read(diaryWeeklyCheckInDataProvider.future);

      final shown = await container
          .read(diaryWeeklyCheckInActionsProvider)
          .showWeeklyCheckInAgain(dismissedPending);
      await container.pump();
      await container.read(
        checkin_provider.calorieWeeklyCheckInDataProvider.future,
      );

      final settings = await settingsRepository.readSettings();
      expect(shown, isTrue);
      expect(
        settings.pendingWeeklyCheckIn?.windowKey,
        dismissedPending.windowKey,
      );
      expect(settings.pendingWeeklyCheckIn?.isDismissed, isFalse);
      expect(checkInDataBuildCount, 2);
    },
  );
}

CalorieWeeklyCheckInData _weeklyCheckInData(
  PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
) {
  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: false,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

PendingCalorieGoalWeeklyCheckIn _pendingWeeklyCheckIn() {
  return PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: DateTime(2026, 4, 8),
    windowEndDate: DateTime(2026, 4, 14),
    dueDate: DateTime(2026, 4, 15),
  );
}

CalorieGoalSettings _settingsWithGoal() {
  return CalorieGoalSettings.single(
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
    effectiveDate: DateTime(2026, 4, 8),
    source: CalorieGoalSource.calculator,
  );
}
