import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

/// Days in one goal run/carryover redistribution segment.
const int calorieGoalRunLengthDays = 7;

/// Resolve the balance cycle start for a given day.
DateTime resolveCalorieBalanceCycleStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
  DateTime? fallbackStartDate,
  DateTime? firstEntryDate,
}) {
  final normalizedDay = normalizeLocalDay(day);
  DateTime resolvedStartDate;
  final activeGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  if (activeGoalEntry?.hasGoal == true) {
    final resolvedAnchor =
        settings.cycleAnchorEntryForDay(normalizedDay) ?? activeGoalEntry;
    if (resolvedAnchor != null) {
      resolvedStartDate = normalizeLocalDay(
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
      normalizeLocalDay(fallbackStartDate ?? normalizedDay);
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
  final normalizedStartDate = normalizeLocalDay(startDate);
  if (firstEntryDate == null) {
    return normalizedStartDate;
  }
  final normalizedFirstEntryDate = normalizeLocalDay(firstEntryDate);
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
  final normalizedDay = normalizeLocalDay(day);
  final countingGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  final anchorEntry = countingGoalEntry == null
      ? null
      : settings.cycleAnchorEntryForDay(normalizedDay) ?? countingGoalEntry;
  if (anchorEntry == null) {
    return normalizedDay;
  }

  final cycleStart = normalizeLocalDay(anchorEntry.effectiveCountingStartDate);
  final elapsedDays = localDaysBetween(cycleStart, normalizedDay);
  if (elapsedDays <= 0) {
    return cycleStart;
  }
  final runOffset = elapsedDays % calorieGoalRunLengthDays;
  return addLocalDays(normalizedDay, -runOffset);
}

/// Number of the 7-day run of the current goal that holds [day], starting
/// at 1, or `null` without a counting goal.
int? resolveCalorieGoalRunNumber({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final normalizedDay = normalizeLocalDay(day);
  final countingGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  if (countingGoalEntry == null) return null;
  final anchorEntry =
      settings.cycleAnchorEntryForDay(normalizedDay) ?? countingGoalEntry;
  final cycleStart = normalizeLocalDay(anchorEntry.effectiveCountingStartDate);
  final elapsedDays = localDaysBetween(cycleStart, normalizedDay);
  if (elapsedDays < 0) return null;
  return elapsedDays ~/ calorieGoalRunLengthDays + 1;
}

/// Resolve the active 7-day run end for a given day.
DateTime resolveCalorieGoalRunEndDate({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final runStart = resolveCalorieGoalRunStartDate(settings: settings, day: day);
  return addLocalDays(runStart, calorieGoalRunLengthDays - 1);
}

/// Resolve remaining days in the active run, including [day].
int resolveRemainingCalorieGoalRunDays({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final normalizedDay = normalizeLocalDay(day);
  final runEnd = resolveCalorieGoalRunEndDate(settings: settings, day: day);
  return localDaysBetween(normalizedDay, runEnd) + 1;
}

/// Resolve where carryover starts for the current 7-day run.
DateTime resolveCalorieCarryoverStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
  required DateTime balanceStartDate,
}) {
  final normalizedDay = normalizeLocalDay(day);
  final normalizedBalanceStart = normalizeLocalDay(balanceStartDate);
  if (normalizedBalanceStart.isAfter(normalizedDay)) {
    return normalizedBalanceStart;
  }

  final runStartDate = resolveCalorieGoalRunStartDate(
    settings: settings,
    day: normalizedDay,
  );
  if (runStartDate.isAfter(normalizedBalanceStart)) {
    return runStartDate;
  }
  return normalizedBalanceStart;
}
