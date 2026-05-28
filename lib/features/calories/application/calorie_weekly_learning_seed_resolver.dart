import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Replays prior weekly windows to find the seed for [pendingWeeklyCheckIn].
CalorieWeeklyLearningSeed resolveCascadedPreviousLearningSeedForWindow({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  required CalorieWeeklyCheckInWindowDates dates,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
  required Map<String, int> activeKcalByDay,
  required Set<String> heartDayKeys,
}) {
  final anchorEntry = dates.anchorEntry;
  if (anchorEntry == null) {
    return baseLearningSeedForWindow(
      settings: settings,
      windowStartDate: pendingWeeklyCheckIn.windowStartDate,
      windowEndDate: pendingWeeklyCheckIn.windowEndDate,
      anchorEntry: null,
    );
  }
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  final firstWindowCountedDayCount =
      CalorieWeeklyWindowResolver.windowLengthDaysForStart(
        anchorEntry: anchorEntry,
        windowStartDate: windowStartDate,
      );
  final firstWindowEndDate = resolveCalorieWeeklyWindowEndDate(
    windowStartDate: windowStartDate,
    countedDayCount: firstWindowCountedDayCount,
  );
  var seed = baseLearningSeedForWindow(
    settings: settings,
    windowStartDate: windowStartDate,
    windowEndDate: firstWindowEndDate,
    anchorEntry: anchorEntry,
  );

  while (windowStartDate.isBefore(pendingWeeklyCheckIn.windowStartDate)) {
    final countedDayCount =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final windowEndDate = resolveCalorieWeeklyWindowEndDate(
      windowStartDate: windowStartDate,
      countedDayCount: countedDayCount,
    );
    final previousWindow = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: nextDiaryDay(windowEndDate),
    );
    final previousDates = resolveCalorieWeeklyCheckInWindowDates(
      settings: settings,
      pendingWeeklyCheckIn: previousWindow,
    );
    final learningIntakeData = resolveWeeklyLearningIntakeData(
      days: previousDates.learningDays,
      calorieEntriesByDay: calorieEntriesByDay,
      settings: settings,
      heartDayKeys: heartDayKeys,
    );
    if (learningIntakeData.blockedReason != null) {
      return seed;
    }

    final weightData = mergeWeeklyCheckInWeights(
      dates: previousDates,
      anchorEntry: previousDates.anchorEntry,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
    if (weightData.weightPoints.length < 2) {
      return seed;
    }

    final calculatorProfile =
        CalorieWeeklyWindowResolver.calculatorProfileForDay(
          settings: settings,
          day: previousWindow.windowEndDate,
        );
    final goalMode = calculatorProfile?.goalMode ?? CalorieGoalMode.maintain;
    final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
      previousGoalKcal: seed.previousGoalKcal,
      previousLearnedTdeeKcal: seed.previousLearnedTdeeKcal,
      goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
          ? 0
          : calculatorProfile?.goalSpeedKgPerWeek ?? 0,
      isLosing: goalMode == CalorieGoalMode.lose,
      isGaining: goalMode == CalorieGoalMode.gain,
      intakeKcalByDay: learningIntakeData.intakeKcalByDay,
      rawActivityKcalByDay: activityKcalByDay(
        days: previousDates.learningDays,
        activeKcalByDay: activeKcalByDay,
      ),
      weightPoints: weightData.weightPoints,
    );
    seed = CalorieWeeklyLearningSeed(
      previousGoalKcal: calculation.newGoalKcal,
      previousLearnedTdeeKcal: calculation.calculatedBaseTdeeKcal,
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }

  return seed;
}

/// Base learning seed before replaying prior windows.
CalorieWeeklyLearningSeed baseLearningSeedForWindow({
  required CalorieGoalSettings settings,
  required DateTime windowStartDate,
  required DateTime windowEndDate,
  required CalorieGoalHistoryEntry? anchorEntry,
}) {
  return CalorieWeeklyLearningSeed(
    previousGoalKcal: settings.goalKcalForDay(windowEndDate),
    previousLearnedTdeeKcal: previousLearnedTdeeKcalBeforeDay(
      settings: settings,
      day: windowStartDate,
      fallbackDay: windowEndDate,
      anchorEntry: anchorEntry,
    ),
  );
}

/// Learned TDEE seed before [day].
double previousLearnedTdeeKcalBeforeDay({
  required CalorieGoalSettings settings,
  required DateTime day,
  required DateTime fallbackDay,
  required CalorieGoalHistoryEntry? anchorEntry,
}) {
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: fallbackDay,
  );
  if (calculatorProfile != null) {
    return CalorieGoalCalculator.calculate(calculatorProfile).tdeeKcal;
  }
  return settings.goalKcalForDay(fallbackDay);
}
