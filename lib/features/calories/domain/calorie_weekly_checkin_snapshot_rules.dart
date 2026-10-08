import 'package:yamt/features/calories/domain/calorie_goal_learned_transitions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// The settings after the user decided the weekly check-in [pending], so the
/// whole decision is saved at once.
///
/// [training] first sets the training days of the planned run. With [accept],
/// the goal of [snapshot] applies, unless the history already holds it.
/// Otherwise the goal from before the window stays and [snapshot] is kept as
/// rejected. The pending check-in is cleared.
///
/// Returns `null` when the run of [training] ended before [today], so a sheet
/// left open into a later run decides nothing.
CalorieGoalSettings? decideWeeklyCheckIn({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pending,
  required CalorieGoalWeeklyCheckInSnapshot snapshot,
  required bool accept,
  required DateTime today,
  CalorieRunTrainingChoice? training,
}) {
  var next = settings;
  if (training != null) {
    final trained = next.withPlannedRunTrainingDays(training, today: today);
    if (trained == null) {
      return null;
    }
    next = trained;
  }
  if (!accept) {
    next = next.applyWeeklyCheckInGoal(
      completedAt: pending.dueDate,
      dailyKcalGoal: goalKcalBeforeWeeklyCheckIn(
        settings: next,
        checkInWindowStartDate: pending.windowStartDate,
      ),
      weeklyCheckInSnapshot: snapshot.copyWith(isRejected: true),
    );
  } else if (!hasMatchingWeeklyCheckInSnapshot(
    settings: next,
    dailyKcalGoal: snapshot.baseGoalKcal,
    weeklyCheckInSnapshot: snapshot,
  )) {
    next = next.applyWeeklyCheckInGoal(
      completedAt: pending.dueDate,
      dailyKcalGoal: snapshot.baseGoalKcal,
      weeklyCheckInSnapshot: snapshot,
    );
  }
  return next.copyWithPendingWeeklyCheckIn(null);
}

/// Whether the goal history already holds a rejected snapshot for the
/// window of [weeklyCheckIn].
bool hasRejectedWeeklyCheckInSnapshot({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn weeklyCheckIn,
}) {
  return _windowSnapshots(
    settings,
    weeklyCheckIn,
  ).any((snapshot) => snapshot.isRejected);
}

/// Whether [pendingWeeklyCheckIn] differs from the persisted pending
/// check-in. A window that the user already decided (its snapshot is still
/// valid) is never persisted again, so data loaded before the decision does
/// not bring the check-in back.
bool pendingWeeklyCheckInNeedsSave({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final current = settings.pendingWeeklyCheckIn;
  if (current == null) {
    return !_windowSnapshots(
      settings,
      pendingWeeklyCheckIn,
    ).any((snapshot) => !snapshot.isInputDirty);
  }
  return current.windowKey != pendingWeeklyCheckIn.windowKey ||
      current.dismissedAt != pendingWeeklyCheckIn.dismissedAt;
}

Iterable<CalorieGoalWeeklyCheckInSnapshot> _windowSnapshots(
  CalorieGoalSettings settings,
  PendingCalorieGoalWeeklyCheckIn weeklyCheckIn,
) {
  return settings.sortedGoalHistory
      .map((entry) => entry.weeklyCheckInSnapshot)
      .nonNulls
      .where(
        (snapshot) =>
            isSameDiaryDay(
              snapshot.windowStartDate,
              weeklyCheckIn.windowStartDate,
            ) &&
            isSameDiaryDay(snapshot.windowEndDate, weeklyCheckIn.windowEndDate),
      );
}

/// The goal that was active before the check-in window that starts on
/// [checkInWindowStartDate].
double goalKcalBeforeWeeklyCheckIn({
  required CalorieGoalSettings settings,
  required DateTime checkInWindowStartDate,
}) {
  for (final entry in settings.sortedGoalHistory.reversed) {
    if (entry.isWeeklyCheckIn &&
        entry.weeklyCheckInSnapshot != null &&
        !entry.weeklyCheckInSnapshot!.windowStartDate.isBefore(
          checkInWindowStartDate,
        )) {
      continue;
    }
    if (entry.hasGoal) {
      return entry.dailyKcalGoal!;
    }
  }
  return settings.dailyKcalGoal ?? defaultDailyCalorieGoalKcal;
}

/// Whether the goal history already holds [weeklyCheckInSnapshot] with
/// [dailyKcalGoal] for its window.
bool hasMatchingWeeklyCheckInSnapshot({
  required CalorieGoalSettings settings,
  required double dailyKcalGoal,
  required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
}) {
  var hasSameWindowSnapshot = false;
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (!_sameWeeklyCheckInSnapshot(snapshot, weeklyCheckInSnapshot)) {
      continue;
    }
    hasSameWindowSnapshot = true;
    final goalMatches =
        !entry.isWeeklyCheckIn ||
        _sameDouble(entry.dailyKcalGoal, dailyKcalGoal);
    final matches =
        goalMatches &&
        snapshot.isRejected == weeklyCheckInSnapshot.isRejected &&
        snapshot.lowConfidence == weeklyCheckInSnapshot.lowConfidence &&
        _sameDouble(
          snapshot.trendWeightChangePerDay,
          weeklyCheckInSnapshot.trendWeightChangePerDay,
        ) &&
        _sameDouble(
          snapshot.measuredTdeeKcal,
          weeklyCheckInSnapshot.measuredTdeeKcal,
        ) &&
        _sameDouble(
          snapshot.calculatedTdeeKcal,
          weeklyCheckInSnapshot.calculatedTdeeKcal,
        ) &&
        _sameDouble(
          snapshot.baseGoalKcal,
          weeklyCheckInSnapshot.baseGoalKcal,
        ) &&
        _sameDouble(
          snapshot.macroWeightKg,
          weeklyCheckInSnapshot.macroWeightKg,
        ) &&
        snapshot.inputHash == weeklyCheckInSnapshot.inputHash &&
        snapshot.invalidatedAt == weeklyCheckInSnapshot.invalidatedAt;
    if (!matches) {
      return false;
    }
  }
  return hasSameWindowSnapshot;
}

bool _sameWeeklyCheckInSnapshot(
  CalorieGoalWeeklyCheckInSnapshot left,
  CalorieGoalWeeklyCheckInSnapshot right,
) {
  return isSameDiaryDay(left.windowStartDate, right.windowStartDate) &&
      isSameDiaryDay(left.windowEndDate, right.windowEndDate);
}

bool _sameDouble(double? left, double? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return (left - right).abs() < 0.0001;
}
