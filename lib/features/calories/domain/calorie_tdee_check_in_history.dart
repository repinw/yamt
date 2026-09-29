import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// The TDEE that one confirmed weekly check-in left in effect.
@immutable
class CalorieTdeeCheckIn {
  /// Creates one confirmed check-in.
  const new({
    required this.day,
    required this.tdeeKcal,
    required this.calculatedTdeeKcal,
    required this.isRejected,
  });

  /// Day on which the check-in took effect.
  final DateTime day;

  /// TDEE the next week counts with: the new value, or the kept old one.
  final double tdeeKcal;

  /// TDEE the check-in calculated.
  final double calculatedTdeeKcal;

  /// Whether the user kept the old TDEE instead of [calculatedTdeeKcal].
  final bool isRejected;
}

/// The TDEE of the current goal: the calculator estimate at its start and one
/// value per confirmed weekly check-in, oldest first.
@immutable
class CalorieTdeeHistory {
  /// Creates a TDEE history.
  const new({required this.startTdeeKcal, required this.checkIns});

  /// Resolves the history from the goal history in [settings].
  ///
  /// A check-in counts only after the user decided on it: an entry for the
  /// window of the still pending check-in is left out.
  factory fromSettings(CalorieGoalSettings settings) {
    final history = settings.sortedGoalHistory;
    final startIndex = history.lastIndexWhere(
      (entry) =>
          entry.hasGoal && entry.source != CalorieGoalSource.weeklyCheckIn,
    );
    final startProfile = startIndex < 0
        ? null
        : history[startIndex].calculatorProfile;
    final startTdeeKcal = startProfile == null
        ? null
        : CalorieGoalCalculator.calculate(startProfile).tdeeKcal;
    final pending = settings.pendingWeeklyCheckIn;
    final pendingStart = pending == null
        ? null
        : diaryDayKey(pending.windowStartDate);

    final checkIns = <CalorieTdeeCheckIn>[];
    var keptTdeeKcal = startTdeeKcal;
    for (final entry in history.skip(startIndex + 1)) {
      final snapshot = _confirmedSnapshot(entry, pendingStart);
      if (snapshot == null) continue;
      final calculated = snapshot.calculatedTdeeKcal;
      final tdeeKcal = snapshot.isRejected
          ? keptTdeeKcal ?? calculated
          : calculated;
      checkIns.add(
        CalorieTdeeCheckIn(
          day: normalizeDiaryDay(entry.effectiveDate),
          tdeeKcal: tdeeKcal,
          calculatedTdeeKcal: calculated,
          isRejected: snapshot.isRejected,
        ),
      );
      keptTdeeKcal = tdeeKcal;
    }
    return CalorieTdeeHistory(
      startTdeeKcal: startTdeeKcal,
      checkIns: List<CalorieTdeeCheckIn>.unmodifiable(checkIns),
    );
  }

  /// TDEE of the calculator at the start of the goal, or `null` for a goal
  /// typed in by hand.
  final double? startTdeeKcal;

  /// Confirmed check-ins, oldest first.
  final List<CalorieTdeeCheckIn> checkIns;
}

CalorieGoalWeeklyCheckInSnapshot? _confirmedSnapshot(
  CalorieGoalHistoryEntry entry,
  String? pendingWindowStartKey,
) {
  final snapshot = entry.weeklyCheckInSnapshot;
  if (entry.source != CalorieGoalSource.weeklyCheckIn || snapshot == null) {
    return null;
  }
  if (diaryDayKey(snapshot.windowStartDate) == pendingWindowStartKey) {
    return null;
  }
  return snapshot;
}
