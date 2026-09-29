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

/// The TDEE of one goal: the calculator estimate at its start and one value
/// per confirmed weekly check-in, oldest first.
@immutable
class CalorieTdeeHistory {
  /// Creates a TDEE history.
  const new({
    required this.startDay,
    required this.startTdeeKcal,
    required this.checkIns,
  });

  /// Resolves the history of the current goal in [settings], or an empty
  /// history without a goal.
  factory fromSettings(CalorieGoalSettings settings) {
    return CalorieTdeeHistory.perGoal(settings).lastOrNull ??
        const CalorieTdeeHistory(
          startDay: null,
          startTdeeKcal: null,
          checkIns: <CalorieTdeeCheckIn>[],
        );
  }

  /// Resolves one history per goal in [settings], oldest goal first.
  ///
  /// A goal starts with every entry that sets a goal outside a weekly
  /// check-in. A check-in counts only after the user decided on it: an entry
  /// for the window of the still pending check-in is left out.
  static List<CalorieTdeeHistory> perGoal(CalorieGoalSettings settings) {
    final pending = settings.pendingWeeklyCheckIn;
    final pendingStart = pending == null
        ? null
        : diaryDayKey(pending.windowStartDate);
    final histories = <CalorieTdeeHistory>[];
    CalorieGoalHistoryEntry? goal;
    var checkIns = <CalorieTdeeCheckIn>[];
    double? keptTdeeKcal;

    void close() {
      final start = goal;
      if (start == null) return;
      histories.add(
        CalorieTdeeHistory(
          startDay: normalizeDiaryDay(start.effectiveCountingStartDate),
          startTdeeKcal: _calculatorTdee(start),
          checkIns: List<CalorieTdeeCheckIn>.unmodifiable(checkIns),
        ),
      );
    }

    for (final entry in settings.sortedGoalHistory) {
      if (entry.hasGoal && entry.source != CalorieGoalSource.weeklyCheckIn) {
        close();
        goal = entry;
        checkIns = <CalorieTdeeCheckIn>[];
        keptTdeeKcal = _calculatorTdee(entry);
        continue;
      }
      if (goal == null) continue;
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
    close();
    return List<CalorieTdeeHistory>.unmodifiable(histories);
  }

  /// First counted day of the goal, or `null` without a goal.
  final DateTime? startDay;

  /// TDEE of the calculator at the start of the goal, or `null` for a goal
  /// typed in by hand.
  final double? startTdeeKcal;

  /// Confirmed check-ins, oldest first.
  final List<CalorieTdeeCheckIn> checkIns;
}

double? _calculatorTdee(CalorieGoalHistoryEntry entry) {
  final profile = entry.calculatorProfile;
  return profile == null
      ? null
      : CalorieGoalCalculator.calculate(profile).tdeeKcal;
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
