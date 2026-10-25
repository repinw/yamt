import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_weight_point.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

void main() {
  test('reads window weights from daily weights', () {
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start);

    final data = mergeWeeklyCheckInWeights(
      dates: dates,
      anchorEntry: null,
      dailyWeightByDay: {localDayKey(start): 80.4},
    );

    expect(data.weightByDay[localDayKey(start)], 80.4);
    expect(data.weightPoints.single.weightKg, 80.4);
  });

  test('uses anchor profile weight for first window start fallback', () {
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start, isFirstWindow: true);
    final anchorEntry = _settings(start).sortedGoalHistory.single;

    final data = mergeWeeklyCheckInWeights(
      dates: dates,
      anchorEntry: anchorEntry,
      dailyWeightByDay: {localDayKey(dates.nextBoundaryDay): 79},
    );

    expect(data.weightByDay[localDayKey(start)], 80);
    expect(
      data.weightByDay[localDayKey(dates.pendingWeeklyCheckIn.windowEndDate)],
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
        isPauseDay: false,
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
    );
    final missingEnd = validateWeeklyCheckInWeightData(
      dates: dates,
      weightData: CalorieWeeklyCheckInWeightData(
        weightByDay: {localDayKey(start): 80},
        weightPoints: const [
          CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        ],
      ),
      windowDays: windowDays,
      missingIntakeDays: const <DateTime>[],
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

  test('allows Sunday and Monday weights to co-exist in weightPoints '
      'without key collision', () {
    final start = DateTime(2026, 4, 2);
    final end = addLocalDays(start, 6);
    final sunday = end;
    final monday = nextLocalDay(end);

    final dates = CalorieWeeklyCheckInWindowDates(
      pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: start,
        windowEndDate: end,
        dueDate: nextLocalDay(end),
      ),
      anchorEntry: null,
      anchorWeightSourceDay: null,
      learningStartDate: start,
      learningDays: [start, sunday],
      windowDays: [start, sunday],
      learningPreviousBoundaryDay: previousLocalDay(start),
      shouldUseLearningPreviousBoundary: false,
      isFirstWindow: false,
      previousBoundaryDay: null,
      nextBoundaryDay: monday,
    );

    final data = mergeWeeklyCheckInWeights(
      dates: dates,
      anchorEntry: null,
      dailyWeightByDay: {localDayKey(sunday): 80.0, localDayKey(monday): 79.5},
    );

    expect(data.weightByDay[localDayKey(sunday)], 80.0);
    expect(data.weightPoints.length, 2);
    final indices = data.weightPoints.map((pt) => pt.dayIndex).toList();
    expect(indices.contains(dates.dayIndexFor(sunday)), isTrue);
    expect(indices.contains(dates.dayIndexFor(monday)), isTrue);
    final sundayWeight = data.weightPoints
        .firstWhere((pt) => pt.dayIndex == dates.dayIndexFor(sunday))
        .weightKg;
    final mondayWeight = data.weightPoints
        .firstWhere((pt) => pt.dayIndex == dates.dayIndexFor(monday))
        .weightKg;
    expect(sundayWeight, 80.0);
    expect(mondayWeight, 79.5);
  });

  test('blocks when only weigh-ins older than 28 days exist', () {
    final goalStart = DateTime(2026, 1, 5);
    final start = DateTime(2026, 4, 2);
    final dates = _dates(start, learningStartDate: goalStart);

    final blocked = validateWeeklyCheckInWeightData(
      dates: dates,
      weightData: CalorieWeeklyCheckInWeightData(
        weightByDay: {
          localDayKey(goalStart): 82,
          localDayKey(nextLocalDay(goalStart)): 81.8,
        },
        weightPoints: const [
          CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 82),
          CalorieWeeklyCheckInWeightPoint(dayIndex: 1, weightKg: 81.8),
        ],
      ),
      windowDays: const <CalorieWeeklyCheckInWindowDay>[],
      missingIntakeDays: const <DateTime>[],
    );

    expect(
      blocked?.blockedReason,
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
    );
    // The missing day is the start of the 28 days, not the first goal day.
    expect(blocked?.missingWeightDays, [addLocalDays(start, 6 - 27)]);
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
  DateTime? learningStartDate,
}) {
  final end = addLocalDays(start, 6);
  return CalorieWeeklyCheckInWindowDates(
    pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: start,
      windowEndDate: end,
      dueDate: nextLocalDay(end),
    ),
    anchorEntry: null,
    anchorWeightSourceDay: null,
    learningStartDate: learningStartDate ?? start,
    learningDays: [start],
    windowDays: [start],
    learningPreviousBoundaryDay: previousLocalDay(start),
    shouldUseLearningPreviousBoundary: false,
    isFirstWindow: isFirstWindow,
    previousBoundaryDay: null,
    nextBoundaryDay: nextLocalDay(end),
  );
}
