import 'dart:math' as math;

import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

// Made-up check-in for the debug preview: run 4 of a goal that started
// four weeks ago, losing from 81.2 kg towards 75 kg.
const _demoRunNumber = 4;
const _demoGoalDays = 28;
const _demoStartWeightKg = 81.2;
const _demoTrendWeightKg = 78.9;
const _demoPreviousMacroWeightKg = 79.6;
const _demoTargetWeightKg = 75.0;
const _demoWeightNoiseKg = 0.4;
const _demoIntakeKcal = 1642.0;
const _demoIntakeSwingKcal = 180.0;
const _demoPreviousTdeeKcal = 2164.0;
const _demoMeasuredTdeeKcal = 2260.0;
const _demoLearnedTdeeKcal = 2240.0;
const _demoPreviousGoalKcal = 1614.0;
const _demoNewGoalKcal = 1690.0;
const _demoSessionKcal = 250.0;
const Set<int> _demoTrainingOffsets = {0, 2, 4};
const List<double> _demoRunTdeeKcal = [2120.0, 2164.0, _demoLearnedTdeeKcal];
const _demoWeightWobble = 1.7;
const _demoIntakeWobble = 2.3;

/// Days of the demo window.
const calorieDemoWindowDays = 7;

PendingCalorieGoalWeeklyCheckIn _demoWindow(DateTime today) {
  final day = normalizeDiaryDay(today);
  return PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: addDiaryDays(day, -calorieDemoWindowDays),
    windowEndDate: addDiaryDays(day, -1),
    dueDate: day,
  );
}

double _demoTrendOn(int dayIndex) =>
    _demoStartWeightKg -
    (_demoStartWeightKg - _demoTrendWeightKg) * dayIndex / (_demoGoalDays - 1);

double _demoScaleOn(int dayIndex) =>
    _demoTrendOn(dayIndex) +
    math.sin(dayIndex * _demoWeightWobble) * _demoWeightNoiseKg;

/// A ready demo check-in that ended yesterday, or a blocked one without the
/// end weight when [blocked] is set.
CalorieWeeklyCheckInData calorieWeeklyCheckInDemoData({
  required DateTime today,
  bool blocked = false,
}) {
  final window = _demoWindow(today);
  const firstIndex = _demoGoalDays - calorieDemoWindowDays;
  final days = [
    for (var offset = 0; offset < calorieDemoWindowDays; offset++)
      CalorieWeeklyCheckInWindowDay(
        day: addDiaryDays(window.windowStartDate, offset),
        hasEntries: true,
        loggedIntakeKcal:
            _demoIntakeKcal +
            math.cos(offset * _demoIntakeWobble) * _demoIntakeSwingKcal,
        resolvedIntakeKcal:
            _demoIntakeKcal +
            math.cos(offset * _demoIntakeWobble) * _demoIntakeSwingKcal,
        isSkippedIntakeDay: false,
        isPauseDay: false,
        weightKg: blocked && offset == calorieDemoWindowDays - 1
            ? null
            : _demoScaleOn(firstIndex + offset),
      ),
  ];
  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: window,
    shouldAutoOpen: false,
    days: days,
    calculation: blocked
        ? null
        : const CalorieWeeklyCheckInCalculation(
            trendWeightChangePerDay:
                -(_demoStartWeightKg - _demoTrendWeightKg) / _demoGoalDays,
            averageIntakeKcal: _demoIntakeKcal,
            previousTdeeKcal: _demoPreviousTdeeKcal,
            measuredTdeeKcal: _demoMeasuredTdeeKcal,
            calculatedTdeeKcal: _demoLearnedTdeeKcal,
            newGoalKcal: _demoNewGoalKcal,
            dynamicGoalTodayKcal: _demoNewGoalKcal,
          ),
    blockedReason: blocked
        ? CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight
        : null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: blocked ? [window.windowEndDate] : const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.fresh,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
    macroWeightKg: blocked ? null : _demoTrendWeightKg,
  );
}

/// The plan of [calorieWeeklyCheckInDemoData], with the real [macroSettings]
/// and [profile] so the macros look like the user's.
CalorieWeeklyCheckInPlan calorieWeeklyCheckInDemoPlan({
  required DateTime today,
  required MacroGoalSettings macroSettings,
  required CalorieCalculatorProfile? profile,
}) {
  final window = _demoWindow(today);
  final startDate = addDiaryDays(window.windowEndDate, 1 - _demoGoalDays);
  final nextRunDays = [
    for (var offset = 0; offset < calorieDemoWindowDays; offset++)
      addDiaryDays(window.dueDate, offset),
  ];
  return CalorieWeeklyCheckInPlan(
    reviewedRunNumber: _demoRunNumber,
    nextRunNumber: _demoRunNumber + 1,
    reviewedDays: (start: window.windowStartDate, end: window.windowEndDate),
    previousTrainingDayCount: _demoTrainingOffsets.length,
    nextRunDays: nextRunDays,
    suggestedTrainingDays: {
      for (final offset in _demoTrainingOffsets) nextRunDays[offset],
    },
    pauseDays: const {},
    pastDays: const {},
    hasWeeklyTrainingSchedule: true,
    sessionKcal: _demoSessionKcal,
    previousTdeeKcal: _demoPreviousTdeeKcal,
    previousGoalKcal: _demoPreviousGoalKcal,
    measurement: (
      tdeeKcal: _demoLearnedTdeeKcal,
      goalKcal: _demoNewGoalKcal,
      averageIntakeKcal: _demoIntakeKcal,
    ),
    progress: CalorieGoalProgress(
      startDate: startDate,
      startWeightKg: _demoStartWeightKg,
      targetWeightKg: _demoTargetWeightKg,
      weights: [
        for (var index = 0; index < _demoGoalDays; index++)
          (
            day: addDiaryDays(startDate, index),
            scaleWeightKg: index % 3 == 1 ? null : _demoScaleOn(index),
            trendWeightKg: _demoTrendOn(index),
          ),
      ],
      tdeePoints: [
        for (final (index, tdeeKcal) in _demoRunTdeeKcal.indexed)
          (
            runEndDate: addDiaryDays(
              startDate,
              (index + 2) * calorieDemoWindowDays - 1,
            ),
            tdeeKcal: tdeeKcal,
          ),
      ],
    ),
    profile: profile,
    macroSettings: macroSettings,
    previousMacroWeightKg: _demoPreviousMacroWeightKg,
    newMacroWeightKg: _demoTrendWeightKg,
    isLosingWeight: true,
  );
}
