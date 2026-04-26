import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Days in one goal run/carryover redistribution segment.
const int calorieGoalRunLengthDays = 7;

/// Resolve the balance cycle start for a given day.
DateTime resolveCalorieBalanceCycleStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
  DateTime? fallbackStartDate,
  DateTime? firstEntryDate,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  DateTime resolvedStartDate;
  final activeGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  if (activeGoalEntry?.hasGoal == true) {
    final resolvedAnchor =
        settings.cycleAnchorEntryForDay(normalizedDay) ?? activeGoalEntry;
    if (resolvedAnchor != null) {
      resolvedStartDate = normalizeDiaryDay(
        resolvedAnchor.effectiveCountingStartDate,
      );
      return _clampBalanceStartToFirstEntry(
        startDate: resolvedStartDate,
        day: normalizedDay,
        firstEntryDate: firstEntryDate,
      );
    }
  }
  resolvedStartDate =
      settings.nextGoalStartAfterDay(normalizedDay) ??
      normalizeDiaryDay(fallbackStartDate ?? normalizedDay);
  return _clampBalanceStartToFirstEntry(
    startDate: resolvedStartDate,
    day: normalizedDay,
    firstEntryDate: firstEntryDate,
  );
}

DateTime _clampBalanceStartToFirstEntry({
  required DateTime startDate,
  required DateTime day,
  required DateTime? firstEntryDate,
}) {
  final normalizedStartDate = normalizeDiaryDay(startDate);
  if (firstEntryDate == null) {
    return normalizedStartDate;
  }
  final normalizedFirstEntryDate = normalizeDiaryDay(firstEntryDate);
  if (normalizedFirstEntryDate.isAfter(day)) {
    return day;
  }
  if (normalizedStartDate.isBefore(normalizedFirstEntryDate)) {
    return normalizedFirstEntryDate;
  }
  return normalizedStartDate;
}

/// Resolve the active 7-day run start for a given day.
DateTime resolveCalorieGoalRunStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  final countingGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  final anchorEntry = countingGoalEntry == null
      ? null
      : settings.cycleAnchorEntryForDay(normalizedDay) ?? countingGoalEntry;
  if (anchorEntry == null) {
    return normalizedDay;
  }

  final cycleStart = normalizeDiaryDay(anchorEntry.effectiveCountingStartDate);
  final elapsedDays = normalizedDay.difference(cycleStart).inDays;
  if (elapsedDays <= 0) {
    return cycleStart;
  }
  final runOffset = elapsedDays % calorieGoalRunLengthDays;
  return normalizedDay.subtract(Duration(days: runOffset));
}

/// Resolve the active 7-day run end for a given day.
DateTime resolveCalorieGoalRunEndDate({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final runStart = resolveCalorieGoalRunStartDate(
    settings: settings,
    day: day,
  );
  return addDiaryDays(runStart, calorieGoalRunLengthDays - 1);
}

/// Resolve remaining days in the active run, including [day].
int resolveRemainingCalorieGoalRunDays({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  final runEnd = resolveCalorieGoalRunEndDate(settings: settings, day: day);
  return runEnd.difference(normalizedDay).inDays + 1;
}
