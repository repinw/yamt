import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Adjustment for the first day of a balance cycle when the goal starts late.
class CalorieBalanceCycleDayAdjustment {
  /// Creates a balance-cycle day adjustment.
  const CalorieBalanceCycleDayAdjustment({
    required this.paceWindowStart,
    required this.adjustedGoalKcal,
  });

  /// The effective pace window start for the partial day.
  final DateTime paceWindowStart;

  /// The prorated goal kcal for the partial day.
  final double adjustedGoalKcal;
}

/// Resolve the balance cycle start for a given day.
DateTime resolveCalorieBalanceCycleStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
  DateTime? fallbackStartDate,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  final activeGoalEntry = settings.goalEntryForDay(normalizedDay);
  if (activeGoalEntry?.hasGoal == true) {
    final resolvedAnchor =
        settings.cycleAnchorEntryForDay(normalizedDay) ?? activeGoalEntry;
    if (resolvedAnchor != null) {
      return normalizeDiaryDay(resolvedAnchor.effectiveDate);
    }
  }
  return settings.nextGoalStartAfterDay(normalizedDay) ??
      normalizeDiaryDay(fallbackStartDate ?? normalizedDay);
}

/// Resolve a prorated first-day goal for the current balance cycle.
CalorieBalanceCycleDayAdjustment? resolveCalorieBalanceCycleDayAdjustment({
  required CalorieGoalSettings settings,
  required DateTime cycleStartDate,
  required DateTime day,
  required Iterable<CalorieEntry> dayEntries,
  required double dailyGoalKcal,
}) {
  final normalizedCycleStart = normalizeDiaryDay(cycleStartDate);
  final normalizedDay = normalizeDiaryDay(day);
  if (normalizedDay != normalizedCycleStart) {
    return null;
  }

  final cycleStartEntry =
      settings.cycleAnchorEntryForDay(normalizedDay) ??
      settings.goalEntryForDay(normalizedDay);
  if (cycleStartEntry?.hasGoal != true) {
    return null;
  }

  final goalChangedAt = cycleStartEntry!.effectiveChangedAt.toLocal();
  if (!_isSameDay(goalChangedAt, normalizedDay)) {
    return null;
  }

  final hadEntriesBeforeGoal = dayEntries.any((entry) {
    return entry.loggedAt.toLocal().isBefore(goalChangedAt);
  });
  if (hadEntriesBeforeGoal) {
    return null;
  }

  final defaultPaceWindowStart = settings.eatingWindowStartForDay(
    normalizedDay,
  );
  if (!goalChangedAt.isAfter(defaultPaceWindowStart)) {
    return null;
  }

  final paceWindowEnd = settings.eatingWindowEndForDay(normalizedDay);
  final defaultWindowSeconds = paceWindowEnd
      .difference(defaultPaceWindowStart)
      .inSeconds;
  if (defaultWindowSeconds <= 0) {
    return null;
  }

  final remainingWindowSeconds = paceWindowEnd
      .difference(goalChangedAt)
      .inSeconds;
  final adjustedGoalKcal = remainingWindowSeconds <= 0
      ? 0.0
      : dailyGoalKcal * remainingWindowSeconds / defaultWindowSeconds;
  return CalorieBalanceCycleDayAdjustment(
    paceWindowStart: goalChangedAt,
    adjustedGoalKcal: adjustedGoalKcal,
  );
}

bool _isSameDay(DateTime left, DateTime right) {
  return normalizeDiaryDay(left) == normalizeDiaryDay(right);
}
