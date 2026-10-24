import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// The completed check-in windows of the goal active on [today].
List<PendingCalorieGoalWeeklyCheckIn> resolveCalorieDebugWeeklyCheckInWindows({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }

  final windows = <PendingCalorieGoalWeeklyCheckIn>[];
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  while (true) {
    final windowLengthDays =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final dueDate = addDiaryDays(windowStartDate, windowLengthDays);
    if (dueDate.isAfter(today)) {
      break;
    }
    final windowEndDate = addDiaryDays(windowStartDate, windowLengthDays - 1);
    windows.add(
      PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: windowStartDate,
        windowEndDate: windowEndDate,
        dueDate: dueDate,
      ),
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
  return List<PendingCalorieGoalWeeklyCheckIn>.unmodifiable(windows);
}

/// The snake-case name of a blocked reason.
String calorieDebugBlockedReasonName(CalorieWeeklyCheckInBlockedReason reason) {
  return switch (reason) {
    CalorieWeeklyCheckInBlockedReason.missingIntakeDays =>
      'missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays =>
      'too_many_missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage =>
      'skipped_day_without_prior_average',
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight =>
      'missing_window_start_weight',
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight =>
      'missing_window_end_weight',
    CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
      'unstable_weight_data',
  };
}

/// Groups [entries] by diary day key.
Map<String, List<CalorieEntry>> calorieDebugEntriesByDay(
  List<CalorieEntry> entries,
) {
  final entriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in entries) {
    final key = diaryDayKey(entry.loggedAt);
    entriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return entriesByDay;
}
