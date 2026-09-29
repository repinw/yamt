import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

/// TDEE per confirmed weekly check-in, per goal, and when the next check-in
/// is due.
@immutable
class ProgressTdee {
  /// Creates the TDEE progress.
  const new({
    required this.goals,
    required this.firstGoalNumber,
    required this.nextCheckInDay,
    required this.isCheckInOpen,
  });

  /// Resolves the TDEE progress of [scope] from [settings].
  factory fromSettings(
    CalorieGoalSettings settings,
    DateTime today,
    ProgressScope scope,
  ) {
    final goals = CalorieTdeeHistory.perGoal(settings);
    final runEnd = resolveCalorieGoalRunEndDate(settings: settings, day: today);
    return ProgressTdee(
      goals: switch (scope) {
        ProgressScope.goal => goals.isEmpty ? goals : [goals.last],
        ProgressScope.all => goals,
      },
      firstGoalNumber: switch (scope) {
        ProgressScope.goal => goals.length,
        ProgressScope.all => 1,
      },
      nextCheckInDay: nextDiaryDay(runEnd),
      isCheckInOpen: settings.pendingWeeklyCheckIn != null,
    );
  }

  /// One TDEE history per goal, oldest first; the last one is the current
  /// goal.
  final List<CalorieTdeeHistory> goals;

  /// Number among all goals of the first goal in [goals], starting at 1.
  final int firstGoalNumber;

  /// Day on which the next check-in is due.
  final DateTime nextCheckInDay;

  /// Whether a check-in waits for the user's decision.
  final bool isCheckInOpen;

  /// Every check-in of all [goals], oldest first.
  List<CalorieTdeeCheckIn> get checkIns => [
    for (final goal in goals) ...goal.checkIns,
  ];

  /// The TDEE in effect now, or `null` before any value is known.
  double? get currentTdeeKcal {
    final current = goals.lastOrNull;
    return current?.checkIns.lastOrNull?.tdeeKcal ?? current?.startTdeeKcal;
  }

  /// Change of the latest check-in of the current goal against the value
  /// before it.
  double? get lastChangeKcal {
    final current = goals.lastOrNull;
    final checkIns = current?.checkIns ?? const <CalorieTdeeCheckIn>[];
    final latest = checkIns.lastOrNull;
    if (latest == null) return null;
    final previous = checkIns.length > 1
        ? checkIns[checkIns.length - 2].tdeeKcal
        : current?.startTdeeKcal;
    return previous == null ? null : latest.tdeeKcal - previous;
  }
}
