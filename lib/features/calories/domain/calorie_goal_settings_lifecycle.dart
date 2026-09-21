import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Goal lifecycle mutations (reached, prompt handled, ended) for
/// [CalorieGoalSettings].
extension CalorieGoalSettingsLifecycle on CalorieGoalSettings {
  /// Marks the active non-check-in goal as reached without starting a new
  /// goal cycle. Returns this instance if there is no markable active goal.
  CalorieGoalSettings markActiveGoalReached(
    DateTime reachedAt, {
    required double weightKg,
  }) {
    final active = cycleAnchorEntryForDay(reachedAt);
    if (active == null || active.reachedAt != null) {
      return this;
    }
    return _replaceEntry(
      active,
      active.copyWith(
        reachedAt: normalizeDiaryDay(reachedAt),
        reachedWeightKg: weightKg,
      ),
      updatedAt: reachedAt,
    );
  }

  /// Marks the reached-goal prompt as explicitly answered by the user.
  CalorieGoalSettings markGoalReachedPromptHandled(DateTime handledAt) {
    final active = cycleAnchorEntryForDay(handledAt);
    if (active == null ||
        active.reachedAt == null ||
        active.reachedPromptHandledAt != null) {
      return this;
    }
    return _replaceEntry(
      active,
      active.copyWith(reachedPromptHandledAt: handledAt),
      updatedAt: handledAt,
    );
  }

  /// Ends the active goal without removing its history entry.
  CalorieGoalSettings markActiveGoalEnded(
    DateTime endedAt, {
    double? weightKg,
  }) {
    final active = cycleAnchorEntryForDay(endedAt);
    if (active == null || active.endedAt != null) {
      return this;
    }
    return _replaceEntry(
      active,
      active.copyWith(
        endedAt: normalizeDiaryDay(endedAt),
        endedWeightKg: weightKg,
      ),
      updatedAt: endedAt,
    );
  }

  CalorieGoalSettings _replaceEntry(
    CalorieGoalHistoryEntry current,
    CalorieGoalHistoryEntry next, {
    required DateTime updatedAt,
  }) {
    return copyWith(
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable([
        for (final entry in goalHistory)
          if (identical(entry, current)) next else entry,
      ]),
      updatedAt: updatedAt,
    );
  }
}
