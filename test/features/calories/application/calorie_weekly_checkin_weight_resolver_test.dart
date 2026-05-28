import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

void main() {
  test('prefers manual weights over health weights for the same day', () {
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start);

    final data = mergeWeeklyCheckInWeights(
      dates: dates,
      anchorEntry: null,
      manualWeightByDay: {diaryDayKey(start): 81},
      representativeWeightByDay: {diaryDayKey(start): 79},
    );

    expect(data.weightByDay[diaryDayKey(start)], 81);
    expect(data.weightPoints.single.weightKg, 81);
  });

  test('uses anchor profile weight for first window start fallback', () {
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start, isFirstWindow: true);
    final anchorEntry = _settings(start).sortedGoalHistory.single;

    final data = mergeWeeklyCheckInWeights(
      dates: dates,
      anchorEntry: anchorEntry,
      manualWeightByDay: {diaryDayKey(dates.nextBoundaryDay): 79},
      representativeWeightByDay: const <String, double>{},
    );

    expect(data.weightByDay[diaryDayKey(start)], 80);
    expect(
      data.weightByDay[diaryDayKey(dates.pendingWeeklyCheckIn.windowEndDate)],
      79,
    );
    expect(data.weightPoints.map((point) => point.dayIndex), [0, 7]);
  });

  test('reports missing start and end weights separately', () {
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start);
    final windowDays = [
      CalorieWeeklyCheckInWindowDay(
        day: start,
        hasEntries: true,
        loggedIntakeKcal: 1000,
        resolvedIntakeKcal: 1000,
        isSkippedIntakeDay: false,
        isHeartDay: false,
        activeKcal: 0,
        weightKg: null,
      ),
    ];

    final missingStart = validateWeeklyCheckInWeightData(
      dates: dates,
      weightData: const CalorieWeeklyCheckInWeightData(
        weightByDay: <String, double>{},
        weightPoints: <CalorieWeeklyCheckInWeightPoint>[],
      ),
      windowDays: windowDays,
      missingIntakeDays: const <DateTime>[],
      usesHealthActivity: false,
    );
    final missingEnd = validateWeeklyCheckInWeightData(
      dates: dates,
      weightData: CalorieWeeklyCheckInWeightData(
        weightByDay: {diaryDayKey(start): 80},
        weightPoints: const [
          CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        ],
      ),
      windowDays: windowDays,
      missingIntakeDays: const <DateTime>[],
      usesHealthActivity: false,
    );

    expect(
      missingStart?.blockedReason,
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
    );
    expect(
      missingEnd?.blockedReason,
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
    );
  });

  test('groups manual weights by normalized day', () {
    final day = DateTime(2026, 4, 2, 18);

    final weights = manualWeightByDay([
      ManualHealthWeightEntry(day: day, weightKg: 82),
    ]);

    expect(weights, {diaryDayKey(DateTime(2026, 4, 2)): 82});
  });
}

CalorieGoalSettings _settings(DateTime start) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: const CalorieCalculatorProfile.defaults(),
    effectiveDate: start,
  );
}

CalorieWeeklyCheckInWindowDates _dates(
  DateTime start, {
  bool isFirstWindow = false,
}) {
  final end = addDiaryDays(start, 6);
  return CalorieWeeklyCheckInWindowDates(
    pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: start,
      windowEndDate: end,
      dueDate: nextDiaryDay(end),
    ),
    anchorEntry: null,
    anchorWeightSourceDay: null,
    learningStartDate: start,
    learningDays: [start],
    windowDays: [start],
    learningPreviousBoundaryDay: previousDiaryDay(start),
    shouldUseLearningPreviousBoundary: false,
    isFirstWindow: isFirstWindow,
    previousBoundaryDay: null,
    nextBoundaryDay: nextDiaryDay(end),
  );
}
