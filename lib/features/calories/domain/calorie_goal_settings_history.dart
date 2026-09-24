import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// History mutation extension for [CalorieGoalSettings].
extension CalorieGoalSettingsHistoryMutations on CalorieGoalSettings {
  /// Applies a new goal change to the history.
  CalorieGoalSettings applyGoalChange({
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    DateTime? countingStartDate,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    bool replaceFutureHistory = false,
    bool preserveSameDayGoalEntries = false,
  }) {
    final effectiveDate = normalizeDiaryDay(changedAt);
    final normalizedCountingStartDate = resolveNormalizedCountingStartDate(
      effectiveDate: changedAt,
      countingStartDate: countingStartDate,
    );
    final nextHistory = _buildNextGoalHistory(
      effectiveDate: effectiveDate,
      changedAt: changedAt,
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      countingStartDate: normalizedCountingStartDate,
      source: source,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
      replaceFutureHistory: replaceFutureHistory,
      preserveSameDayGoalEntries: preserveSameDayGoalEntries,
    );
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: currentCalorieMathVersion,
      activityTrackingStartDate: activityTrackingStartDate,
      updatedAt: changedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      pendingWeeklyCheckIn: null,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
      trainingWeekdays: calculatorProfile?.trainingWeekdays ?? trainingWeekdays,
      trainingDayKcalOffset:
          calculatorProfile?.trainingDayKcalOffset ?? trainingDayKcalOffset,
      trainingDayOverrides: trainingDayOverrides,
      pauseDayKeys: pauseDayKeys,
    );
  }

  List<CalorieGoalHistoryEntry> _buildNextGoalHistory({
    required DateTime effectiveDate,
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime countingStartDate,
    required CalorieGoalSource source,
    required CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    required bool replaceFutureHistory,
    required bool preserveSameDayGoalEntries,
  }) {
    final filtered = <CalorieGoalHistoryEntry>[
      for (final entry in sortedGoalHistory)
        if (_shouldKeepGoalHistoryEntry(
          entry: entry,
          effectiveDate: effectiveDate,
          source: source,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
          replaceFutureHistory: replaceFutureHistory,
          preserveSameDayGoalEntries: preserveSameDayGoalEntries,
        ))
          entry,
      CalorieGoalHistoryEntry(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: calculatorProfile,
        effectiveDate: effectiveDate,
        changedAt: changedAt,
        countingStartDate: countingStartDate,
        source: source,
        weeklyCheckInSnapshot: weeklyCheckInSnapshot,
      ),
    ];
    return filtered..sort(_compareGoalEntries);
  }

  /// Removes the latest non-weekly-check-in goal entry.
  CalorieGoalSettings withoutLatestGoalEntry() {
    final history = sortedGoalHistory;
    final latestGoalIndex = history.lastIndexWhere((entry) => entry.hasGoal);
    if (latestGoalIndex < 0) return this;

    final nextHistory = List<CalorieGoalHistoryEntry>.from(history)
      ..removeAt(latestGoalIndex);
    final prevIdx = nextHistory.lastIndexWhere((entry) => entry.hasGoal);
    final previousGoal = prevIdx >= 0 ? nextHistory[prevIdx] : null;

    return copyWith(
      dailyKcalGoal: previousGoal?.dailyKcalGoal,
      calculatorProfile: previousGoal?.calculatorProfile,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
    );
  }

  /// Whether [day] was marked as a skipped intake day.
  bool isSkippedIntakeDay(DateTime day) {
    return skippedIntakeDayKeys.contains(diaryDayKey(day));
  }

  /// Dismisses the pending weekly check in.
  CalorieGoalSettings dismissPendingWeeklyCheckIn(DateTime dismissedAt) {
    final pending = pendingWeeklyCheckIn;
    if (pending == null) return this;
    return copyWithPendingWeeklyCheckIn(
      pending.copyWith(dismissedAt: dismissedAt),
    );
  }

  /// Sets whether [day] is marked as a skipped intake day.
  CalorieGoalSettings setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) {
    final dayKey = diaryDayKey(day);
    final nextKeys = List<String>.from(skippedIntakeDayKeys);
    if (isSkipped && !nextKeys.contains(dayKey)) {
      nextKeys.add(dayKey);
    } else if (!isSkipped && nextKeys.contains(dayKey)) {
      nextKeys.remove(dayKey);
    }
    nextKeys.sort();
    return copyWith(skippedIntakeDayKeys: List<String>.unmodifiable(nextKeys));
  }

  /// Mark weekly check-in snapshots dirty from a changed diary day.
  CalorieGoalSettings invalidateWeeklyCheckInSnapshotsFromDay({
    required DateTime day,
    required DateTime invalidatedAt,
  }) {
    final normalizedDay = normalizeDiaryDay(day);
    var didInvalidate = false;
    final nextEntries = <CalorieGoalHistoryEntry>[
      for (final entry in goalHistory)
        _dirtyGoalHistoryEntrySnapshot(
          entry: entry,
          day: normalizedDay,
          invalidatedAt: invalidatedAt,
          didInvalidate: () => didInvalidate = true,
        ),
    ];
    if (!didInvalidate) return this;
    return copyWith(
      updatedAt: invalidatedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextEntries),
    );
  }
}

int _compareGoalEntries(
  CalorieGoalHistoryEntry left,
  CalorieGoalHistoryEntry right,
) {
  final byDay = left.effectiveDate.compareTo(right.effectiveDate);
  if (byDay != 0) return byDay;
  return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
}

bool _shouldKeepGoalHistoryEntry({
  required CalorieGoalHistoryEntry entry,
  required DateTime effectiveDate,
  required CalorieGoalSource source,
  required CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
  required bool replaceFutureHistory,
  required bool preserveSameDayGoalEntries,
}) {
  if (isSameDiaryDay(entry.effectiveDate, effectiveDate)) {
    if (preserveSameDayGoalEntries && entry.hasGoal && !entry.isWeeklyCheckIn) {
      return true;
    }
    if (entry.isWeeklyCheckIn != (source == CalorieGoalSource.weeklyCheckIn)) {
      return true;
    }
    if (source == CalorieGoalSource.weeklyCheckIn &&
        entry.source == CalorieGoalSource.weeklyCheckIn &&
        weeklyCheckInSnapshot != null &&
        entry.weeklyCheckInSnapshot != null &&
        !_sameWeeklyCheckInWindow(
          entry.weeklyCheckInSnapshot!,
          weeklyCheckInSnapshot,
        )) {
      return true;
    }
    return false;
  }
  if (!replaceFutureHistory) return true;
  return entry.effectiveDate.isBefore(effectiveDate);
}

bool _sameWeeklyCheckInWindow(
  CalorieGoalWeeklyCheckInSnapshot left,
  CalorieGoalWeeklyCheckInSnapshot right,
) {
  return isSameDiaryDay(left.windowStartDate, right.windowStartDate) &&
      isSameDiaryDay(left.windowEndDate, right.windowEndDate);
}

CalorieGoalHistoryEntry _dirtyGoalHistoryEntrySnapshot({
  required CalorieGoalHistoryEntry entry,
  required DateTime day,
  required DateTime invalidatedAt,
  required void Function() didInvalidate,
}) {
  final snapshot = entry.weeklyCheckInSnapshot;
  if (snapshot == null || snapshot.isInputDirty) return entry;
  final windowStartDate = normalizeDiaryDay(snapshot.windowStartDate);
  final windowEndDate = normalizeDiaryDay(snapshot.windowEndDate);
  if (day.isBefore(windowStartDate) || day.isAfter(windowEndDate)) {
    return entry;
  }
  didInvalidate();
  return entry.copyWith(
    weeklyCheckInSnapshot: snapshot.copyWith(
      inputHash: null,
      invalidatedAt: invalidatedAt,
    ),
  );
}
