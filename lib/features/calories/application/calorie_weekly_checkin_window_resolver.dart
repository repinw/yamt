import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Resolves the latest completed weekly check-in window.
PendingCalorieGoalWeeklyCheckIn? resolveLatestCompletedCalorieWeeklyCheckIn({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return null;
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return null;
  }

  PendingCalorieGoalWeeklyCheckIn? latestWindow;
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  while (true) {
    final countedDayCount =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final windowEndDate = resolveCalorieWeeklyWindowEndDate(
      windowStartDate: windowStartDate,
      countedDayCount: countedDayCount,
    );
    final dueDate = nextDiaryDay(windowEndDate);
    if (dueDate.isAfter(today)) {
      return latestWindow;
    }
    latestWindow = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: dueDate,
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
}

/// Resolves the next weekly check-in that needs user attention.
PendingCalorieGoalWeeklyCheckIn? resolvePendingCalorieWeeklyCheckIn({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return null;
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return null;
  }
  final firstWindowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );

  final resolvedWindowKeys = <String>{};
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.learnedTdeeSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (snapshot.windowStartDate.isBefore(firstWindowStartDate)) {
      continue;
    }
    resolvedWindowKeys.add(
      calorieWeeklyCheckInWindowKey(
        snapshot.windowStartDate,
        snapshot.windowEndDate,
      ),
    );
  }

  final persistedPending = settings.pendingWeeklyCheckIn;
  PendingCalorieGoalWeeklyCheckIn? resolvedPersistedPending;
  var windowStartDate = firstWindowStartDate;
  while (true) {
    final countedDayCount =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final windowEndDate = resolveCalorieWeeklyWindowEndDate(
      windowStartDate: windowStartDate,
      countedDayCount: countedDayCount,
    );
    final dueDate = nextDiaryDay(windowEndDate);
    if (dueDate.isAfter(today)) {
      return resolvedPersistedPending;
    }
    final windowKey = calorieWeeklyCheckInWindowKey(
      windowStartDate,
      windowEndDate,
    );
    final isPersistedPending =
        persistedPending != null && persistedPending.windowKey == windowKey;
    if (resolvedWindowKeys.contains(windowKey)) {
      if (isPersistedPending) {
        resolvedPersistedPending = persistedPending;
      }
      windowStartDate = nextDiaryDay(windowEndDate);
      continue;
    }
    if (isPersistedPending) {
      return persistedPending;
    }

    return PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: dueDate,
    );
  }
}

/// Resolves whether learned TDEE data is fresh enough.
CalorieLearnedTdeeFreshness resolveCalorieLearnedTdeeFreshness({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final learnedAt = settings.latestLearnedTdeeChangedAt;
  if (learnedAt == null) {
    return CalorieLearnedTdeeFreshness.none;
  }
  final daysSinceLearned = today
      .difference(normalizeDiaryDay(learnedAt))
      .inDays;
  if (daysSinceLearned >= learnedTdeeUrgentStaleAfterDays) {
    return CalorieLearnedTdeeFreshness.urgent;
  }
  if (daysSinceLearned >= learnedTdeeStaleAfterDays) {
    return CalorieLearnedTdeeFreshness.stale;
  }
  return CalorieLearnedTdeeFreshness.fresh;
}

/// Resolves dates used to calculate a weekly check-in.
CalorieWeeklyCheckInWindowDates resolveCalorieWeeklyCheckInWindowDates({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final windowLengthDays = calorieWeeklyWindowLengthDays(pendingWeeklyCheckIn);
  final learningStartDate = calorieWeeklyLearningStartDateForCheckIn(
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
  );
  final windowDays = <DateTime>[
    for (var index = 0; index < windowLengthDays; index += 1)
      addDiaryDays(pendingWeeklyCheckIn.windowStartDate, index),
  ];
  final learningDays = buildCalorieWeeklyInclusiveDays(
    startDate: learningStartDate,
    endDate: pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorEntry = settings.cycleAnchorEntryForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorWeightSourceDay = anchorEntry == null
      ? null
      : CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
          anchorEntry: anchorEntry,
          windowStartDate: pendingWeeklyCheckIn.windowStartDate,
        );
  final learningPreviousBoundaryDay = previousDiaryDay(learningStartDate);
  final shouldUseLearningPreviousBoundary =
      learningPreviousBoundaryDay.isAfter(
        normalizeDiaryDay(
          anchorEntry?.effectiveCountingStartDate ?? learningStartDate,
        ),
      ) ||
      learningStartDate.isAfter(pendingWeeklyCheckIn.windowStartDate);
  final isFirstWindow =
      anchorEntry != null &&
      CalorieWeeklyWindowResolver.isFirstWindowStart(
        anchorEntry: anchorEntry,
        windowStartDate: pendingWeeklyCheckIn.windowStartDate,
      );
  return CalorieWeeklyCheckInWindowDates(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    anchorEntry: anchorEntry,
    anchorWeightSourceDay: anchorWeightSourceDay,
    learningStartDate: learningStartDate,
    learningDays: learningDays,
    windowDays: windowDays,
    learningPreviousBoundaryDay: learningPreviousBoundaryDay,
    shouldUseLearningPreviousBoundary: shouldUseLearningPreviousBoundary,
    isFirstWindow: isFirstWindow,
    previousBoundaryDay: isFirstWindow
        ? null
        : previousDiaryDay(pendingWeeklyCheckIn.windowStartDate),
    nextBoundaryDay: nextDiaryDay(pendingWeeklyCheckIn.windowEndDate),
  );
}

/// Stable key for one weekly check-in window.
String calorieWeeklyCheckInWindowKey(DateTime startDate, DateTime endDate) {
  return '${diaryDayKey(startDate)}:${diaryDayKey(endDate)}';
}

/// Resolves an inclusive window end from a start and counted length.
DateTime resolveCalorieWeeklyWindowEndDate({
  required DateTime windowStartDate,
  required int countedDayCount,
}) {
  assert(countedDayCount > 0, 'Window must contain counted days.');
  return addDiaryDays(windowStartDate, countedDayCount - 1);
}

/// Number of days in the check-in window.
int calorieWeeklyWindowLengthDays(
  PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
) {
  return pendingWeeklyCheckIn.windowEndDate
          .difference(pendingWeeklyCheckIn.windowStartDate)
          .inDays +
      1;
}

/// Builds normalized inclusive day list.
List<DateTime> buildCalorieWeeklyInclusiveDays({
  required DateTime startDate,
  required DateTime endDate,
}) {
  final normalizedStartDate = normalizeDiaryDay(startDate);
  final normalizedEndDate = normalizeDiaryDay(endDate);
  return <DateTime>[
    for (
      var day = normalizedStartDate;
      !day.isAfter(normalizedEndDate);
      day = nextDiaryDay(day)
    )
      day,
  ];
}

/// Learning lookback start for a pending check-in.
DateTime calorieWeeklyLearningStartDateForCheckIn({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final anchorEntry = settings.cycleAnchorEntryForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorStartDate = anchorEntry == null
      ? pendingWeeklyCheckIn.windowStartDate
      : CalorieWeeklyWindowResolver.firstWindowStartDate(anchorEntry);
  final oldestAllowedStartDate = pendingWeeklyCheckIn.windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
}
