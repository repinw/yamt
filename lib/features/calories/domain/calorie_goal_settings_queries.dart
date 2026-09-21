import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Goal resolution and querying extension for [CalorieGoalSettings].
extension CalorieGoalSettingsQueries on CalorieGoalSettings {
  /// Earliest counting start day of any user-set goal, if a plan exists.
  DateTime? get firstGoalStartDay {
    DateTime? earliest;
    for (final entry in goalHistory) {
      if (!entry.hasGoal || entry.isWeeklyCheckIn) {
        continue;
      }
      final start = normalizeDiaryDay(entry.effectiveCountingStartDate);
      if (earliest == null || start.isBefore(earliest)) {
        earliest = start;
      }
    }
    return earliest;
  }

  /// Learned TDEE entry effective for the given day.
  CalorieGoalHistoryEntry? learnedTdeeEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? resolvedEntry;
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.hasLearnedTdee) {
        resolvedEntry = entry;
      }
    }
    return resolvedEntry;
  }

  /// Cycle anchor entry for day.
  CalorieGoalHistoryEntry? cycleAnchorEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? anchorEntry;
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.effectiveCountingStartDate.isAfter(normalizedDay)) {
        continue;
      }
      if (!entry.hasGoal || entry.isWeeklyCheckIn) {
        continue;
      }
      anchorEntry = entry;
    }
    return anchorEntry;
  }

  /// Earliest goal anchor that may contribute to the rolling TDEE learning
  /// window. Goal changes do not discard otherwise valid intake/weight days.
  CalorieGoalHistoryEntry? learningAnchorEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.hasGoal && !entry.isWeeklyCheckIn) {
        return entry;
      }
    }
    return null;
  }

  /// Goal entry for day.
  CalorieGoalHistoryEntry? goalEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? resolvedEntry;
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.isWeeklyCheckIn) {
        continue;
      }
      resolvedEntry = entry;
    }
    return resolvedEntry;
  }

  /// Active goal entry for day.
  CalorieGoalHistoryEntry? activeGoalEntryForDay(DateTime day) {
    final entry = goalEntryForDay(day);
    if (entry?.hasGoal != true) {
      return null;
    }
    return entry;
  }

  /// Goal entry that is already counted for the given day.
  CalorieGoalHistoryEntry? countingGoalEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    final entry = goalEntryForDay(normalizedDay);
    if (entry?.hasGoal != true) {
      return null;
    }
    if (entry!.effectiveCountingStartDate.isAfter(normalizedDay)) {
      return null;
    }
    return entry;
  }

  /// Whether the day is a consequence-free practice day for an active goal.
  bool isGoalPracticeDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    final entry = goalEntryForDay(normalizedDay);
    if (entry?.hasGoal != true) {
      return nextGoalStartAfterDay(normalizedDay) != null;
    }
    return entry!.effectiveCountingStartDate.isAfter(normalizedDay);
  }

  /// Next official counting start after day.
  DateTime? nextGoalStartAfterDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    for (final entry in sortedGoalHistory) {
      if (!entry.hasGoal || entry.isWeeklyCheckIn) {
        continue;
      }
      final countingStartDate = entry.effectiveCountingStartDate;
      if (countingStartDate.isAfter(normalizedDay)) {
        return countingStartDate;
      }
    }
    return null;
  }

  /// Unadjusted base goal kcal for day.
  double baseGoalKcalForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? latest;
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.hasGoal) {
        latest = entry;
      }
    }
    if (latest?.dailyKcalGoal != null) {
      return latest!.dailyKcalGoal!;
    }
    return nextGoalStartAfterDay(normalizedDay) == null
        ? defaultDailyCalorieGoalKcal
        : 0.0;
  }

  /// Balance start for window.
  DateTime balanceStartForWindow(Iterable<DateTime> days) {
    final normalizedDays = days.map(normalizeDiaryDay).toList(growable: false)
      ..sort();
    if (normalizedDays.isEmpty) {
      return normalizeDiaryDay(DateTime.now());
    }
    final windowStart = normalizedDays.first;
    final windowEnd = normalizedDays.last;
    final latestChange = _latestChangeInWindow(windowStart, windowEnd);
    if (latestChange != null) {
      return latestChange;
    }
    final activeEntryAtWindowEnd = countingGoalEntryForDay(windowEnd);
    if (activeEntryAtWindowEnd?.hasGoal == true) {
      return windowStart;
    }
    return nextGoalStartAfterDay(windowEnd) ?? windowStart;
  }

  DateTime? _latestChangeInWindow(DateTime windowStart, DateTime windowEnd) {
    DateTime? latest;
    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isBefore(windowStart)) {
        continue;
      }
      if (entry.effectiveDate.isAfter(windowEnd)) {
        break;
      }
      if (entry.isWeeklyCheckIn) {
        continue;
      }
      final counting = entry.effectiveCountingStartDate;
      if (counting.isBefore(windowStart) || counting.isAfter(windowEnd)) {
        continue;
      }
      latest = counting;
    }
    return latest;
  }
}
