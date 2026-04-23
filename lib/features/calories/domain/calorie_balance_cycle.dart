import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Resolve the balance cycle start for a given day.
DateTime resolveCalorieBalanceCycleStartDate({
  required CalorieGoalSettings settings,
  required DateTime day,
  DateTime? fallbackStartDate,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  final activeGoalEntry = settings.countingGoalEntryForDay(normalizedDay);
  if (activeGoalEntry?.hasGoal == true) {
    final resolvedAnchor =
        settings.cycleAnchorEntryForDay(normalizedDay) ?? activeGoalEntry;
    if (resolvedAnchor != null) {
      return normalizeDiaryDay(resolvedAnchor.effectiveCountingStartDate);
    }
  }
  return settings.nextGoalStartAfterDay(normalizedDay) ??
      normalizeDiaryDay(fallbackStartDate ?? normalizedDay);
}
