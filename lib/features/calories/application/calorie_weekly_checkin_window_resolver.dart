import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

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
    final window = _windowFrom(anchorEntry, windowStartDate);
    if (window.dueDate.isAfter(today)) {
      return latestWindow;
    }
    latestWindow = window;
    windowStartDate = window.dueDate;
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
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null || snapshot.isInputDirty) {
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
  var window = _windowFrom(anchorEntry, firstWindowStartDate);
  while (!window.dueDate.isAfter(today)) {
    final nextWindow = _windowFrom(anchorEntry, window.dueDate);
    final isPersistedPending = persistedPending?.windowKey == window.windowKey;
    if (!resolvedWindowKeys.contains(window.windowKey)) {
      return isPersistedPending ? persistedPending : window;
    }
    // The latest due check-in stays open until the user decides, even when
    // an older app already saved a snapshot of its window.
    if (isPersistedPending &&
        !persistedPending!.isDismissed &&
        nextWindow.dueDate.isAfter(today)) {
      return persistedPending;
    }
    window = nextWindow;
  }
  return null;
}

/// The check-in window that starts on [windowStartDate]. It is due on the
/// day after its end.
PendingCalorieGoalWeeklyCheckIn _windowFrom(
  CalorieGoalHistoryEntry anchorEntry,
  DateTime windowStartDate,
) {
  final windowEndDate = resolveCalorieWeeklyWindowEndDate(
    windowStartDate: windowStartDate,
    countedDayCount: CalorieWeeklyWindowResolver.windowLengthDaysForStart(
      anchorEntry: anchorEntry,
      windowStartDate: windowStartDate,
    ),
  );
  return PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: windowStartDate,
    windowEndDate: windowEndDate,
    dueDate: nextLocalDay(windowEndDate),
  );
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
      .difference(normalizeLocalDay(learnedAt))
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
      addLocalDays(pendingWeeklyCheckIn.windowStartDate, index),
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
  final learningPreviousBoundaryDay = previousLocalDay(learningStartDate);
  final shouldUseLearningPreviousBoundary =
      learningPreviousBoundaryDay.isAfter(
        normalizeLocalDay(
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
        : previousLocalDay(pendingWeeklyCheckIn.windowStartDate),
    nextBoundaryDay: nextLocalDay(pendingWeeklyCheckIn.windowEndDate),
  );
}

/// Stable key for one weekly check-in window.
String calorieWeeklyCheckInWindowKey(DateTime startDate, DateTime endDate) {
  return '${localDayKey(startDate)}:${localDayKey(endDate)}';
}

/// Resolves an inclusive window end from a start and counted length.
DateTime resolveCalorieWeeklyWindowEndDate({
  required DateTime windowStartDate,
  required int countedDayCount,
}) {
  assert(countedDayCount > 0, 'Window must contain counted days.');
  return addLocalDays(windowStartDate, countedDayCount - 1);
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
  final normalizedStartDate = normalizeLocalDay(startDate);
  final normalizedEndDate = normalizeLocalDay(endDate);
  return <DateTime>[
    for (
      var day = normalizedStartDate;
      !day.isAfter(normalizedEndDate);
      day = nextLocalDay(day)
    )
      day,
  ];
}

/// First day that the check-in of [pendingWeeklyCheckIn] learns from: the
/// start of the first goal, where the daily TDEE starts.
DateTime calorieWeeklyLearningStartDateForCheckIn({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final windowStart = normalizeLocalDay(pendingWeeklyCheckIn.windowStartDate);
  final start = DailyTdeeSeries.startDay(
    settings,
    pendingWeeklyCheckIn.windowEndDate,
  );
  return start == null || start.isAfter(windowStart) ? windowStart : start;
}
