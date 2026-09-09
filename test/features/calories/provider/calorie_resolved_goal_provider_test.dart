import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';

import '../support/fake_calories_repositories.dart';

ProviderContainer _createContainer({
  required DateTime today,
  required CalorieGoalSettings settings,
}) {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  return ProviderContainer(
    overrides: [
      calorieBalanceNowProvider.overrideWith((ref) => () => today),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
}

void main() {
  test('batch request normalizes diary days for stable cache keys', () {
    final day = DateTime(2026, 4, 14, 13);
    final sameDay = DateTime(2026, 4, 14, 23);
    final otherDay = DateTime(2026, 4, 15);
    final request = ResolvedCalorieGoalDaysRequest.fromDays(<DateTime>[
      day,
      otherDay,
    ]);
    final sameRequest = ResolvedCalorieGoalDaysRequest.fromDays(<DateTime>[
      sameDay,
      otherDay,
    ]);
    final duplicateRequest = ResolvedCalorieGoalDaysRequest.fromDays(
      <DateTime>[day, sameDay, otherDay],
    );
    final reversedRequest = ResolvedCalorieGoalDaysRequest.fromDays(
      <DateTime>[otherDay, day],
    );
    final detailedActivityRequest = ResolvedCalorieGoalDaysRequest.fromDays(
      <DateTime>[day, otherDay],
      forceDetailedActivity: true,
    );

    expect(request, sameRequest);
    expect(request.hashCode, sameRequest.hashCode);
    expect(request, duplicateRequest);
    expect(request == reversedRequest, isFalse);
    expect(request == detailedActivityRequest, isFalse);
  });

  test('resolves batch goals by day key without swapping day data', () async {
    final firstDay = DateTime(2026, 4, 14);
    final secondDay = DateTime(2026, 4, 15);
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      dailyKcalGoal: 2100,
      changedAt: firstDay,
      calculatorProfile: null,
    );
    final container = _createContainer(today: secondDay, settings: settings);
    addTearDown(container.dispose);

    final goals = await container.read(
      resolvedCalorieGoalsForDaysProvider(
        ResolvedCalorieGoalDaysRequest.fromDays(<DateTime>[
          firstDay,
          secondDay,
        ]),
      ).future,
    );

    final firstGoal = goals[diaryDayKey(firstDay)];
    final secondGoal = goals[diaryDayKey(secondDay)];
    expect(
      goals.keys,
      orderedEquals(<String>[
        diaryDayKey(firstDay),
        diaryDayKey(secondDay),
      ]),
    );
    expect(firstGoal, isNotNull);
    expect(firstGoal!.day, normalizeDiaryDay(firstDay));
    expect(firstGoal.goalKcal, 2100);
    expect(secondGoal, isNotNull);
    expect(secondGoal!.day, normalizeDiaryDay(secondDay));
    expect(secondGoal.goalKcal, 2100);
  });

  test(
    'resolves higher goal on training days and budget-neutral deduction '
    'on rest days',
    () async {
      // 2026-04-13 is Monday (weekday 1)
      final monday = DateTime(2026, 4, 13);
      // 2026-04-14 is Tuesday (weekday 2)
      final tuesday = DateTime(2026, 4, 14);

      // 3 training days: Monday (1), Wednesday (3), Friday (5)
      // Base: 2000 kcal, Offset: +200 kcal
      // Training days (3): 2200 kcal
      // Rest days (4): (7*2000 - 3*2200) / 4 = (14000 - 6600) / 4 = 1850 kcal
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            dailyKcalGoal: 2000,
            changedAt: monday,
            calculatorProfile: null,
          )
          .copyWith(
            trainingWeekdays: const [1, 3, 5],
            trainingDayKcalOffset: 200,
          );

      final container = _createContainer(today: monday, settings: settings);
      addTearDown(container.dispose);

      final mondayGoal = await container.read(
        resolvedCalorieGoalForDayProvider(monday).future,
      );
      final tuesdayGoal = await container.read(
        resolvedCalorieGoalForDayProvider(tuesday).future,
      );

      expect(mondayGoal.storedGoalKcal, 2000);
      expect(mondayGoal.goalKcal, 2200);
      expect(tuesdayGoal.storedGoalKcal, 2000);
      expect(tuesdayGoal.goalKcal, 1850);
    },
  );

  test('respects manual day toggle override for training day', () async {
    // 2026-04-14 is Tuesday (normally rest day)
    final tuesday = DateTime(2026, 4, 14);

    final settings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          dailyKcalGoal: 2000,
          changedAt: DateTime(2026, 4),
          calculatorProfile: null,
        )
        .copyWith(
          trainingWeekdays: const [1, 3, 5],
          trainingDayKcalOffset: 200,
        )
        .toggleTrainingDay(tuesday);

    final container = _createContainer(today: tuesday, settings: settings);
    addTearDown(container.dispose);

    final tuesdayGoal = await container.read(
      resolvedCalorieGoalForDayProvider(tuesday).future,
    );

    // Tuesday is now toggled to a training day: gets base + 200 = 2200
    expect(tuesdayGoal.goalKcal, 2200);
  });

  test('does not clamp a resolved goal above the 1200 floor', () async {
    final today = DateTime(2026, 4, 15);
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: DateTime(2026, 4, 14, 9),
      dailyKcalGoal: 1400,
      calculatorProfile: null,
    );

    final container = _createContainer(today: today, settings: settings);
    addTearDown(container.dispose);

    final resolvedGoal = await container.read(
      resolvedCalorieGoalForDayProvider(today).future,
    );

    expect(resolvedGoal.storedGoalKcal, 1400);
    expect(resolvedGoal.goalKcal, 1400);
    expect(resolvedGoal.usedLearnedTdee, isFalse);
    expect(resolvedGoal.wasClampedToMinimum, isFalse);
  });

  test('clamps a resolved goal to the 1200 floor when goal is lower', () async {
    final today = DateTime(2026, 4, 15);
    final settings = const CalorieGoalSettings.empty().applyGoalChange(
      changedAt: DateTime(2026, 4, 14, 9),
      dailyKcalGoal: 1100,
      calculatorProfile: null,
    );

    final container = _createContainer(today: today, settings: settings);
    addTearDown(container.dispose);

    final resolvedGoal = await container.read(
      resolvedCalorieGoalForDayProvider(today).future,
    );

    expect(resolvedGoal.storedGoalKcal, 1100);
    expect(resolvedGoal.goalKcal, 1200);
    expect(resolvedGoal.wasClampedToMinimum, isTrue);
  });

  test(
    'uses saved learned target when weekly check-in snapshot is present',
    () async {
      final startDay = DateTime(2026, 4, 8);
      final today = DateTime(2026, 4, 15);
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: startDay,
            dailyKcalGoal: 2400,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2580,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: startDay,
              windowEndDate: previousDiaryDay(today),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 2580,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );

      final container = _createContainer(today: today, settings: settings);
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.storedGoalKcal, 2580);
      expect(resolvedGoal.goalKcal, 2580);
      expect(resolvedGoal.usedLearnedTdee, isTrue);
    },
  );

  test(
    'does not clamp a learned resolved goal above the 1200 floor',
    () async {
      final today = DateTime(2026, 4, 15);
      final sourceStart = today.subtract(const Duration(days: 7));
      final settings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: sourceStart,
            dailyKcalGoal: 1450,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 1450,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: sourceStart,
              windowEndDate: today.subtract(const Duration(days: 1)),
              trendWeightChangePerDay: 0,
              calculatedTrueTdeeKcal: 1450,
              averageActiveKcal: 0,
              lowConfidence: false,
            ),
          );

      final container = _createContainer(today: today, settings: settings);
      addTearDown(container.dispose);

      final resolvedGoal = await container.read(
        resolvedCalorieGoalForDayProvider(today).future,
      );

      expect(resolvedGoal.goalKcal, 1450);
      expect(resolvedGoal.wasClampedToMinimum, isFalse);
    },
  );
}
