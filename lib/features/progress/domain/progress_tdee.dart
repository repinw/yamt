import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Number of check-ins that the TDEE chart shows at most.
const int progressTdeeMaxCheckIns = 8;

/// TDEE per confirmed weekly check-in and when the next one is due.
@immutable
class ProgressTdee {
  /// Creates the TDEE progress.
  const new({
    required this.startTdeeKcal,
    required this.checkIns,
    required this.nextCheckInDay,
    required this.isCheckInOpen,
  });

  /// Resolves the TDEE progress of the current goal in [settings].
  factory fromSettings(CalorieGoalSettings settings, DateTime today) {
    final history = CalorieTdeeHistory.fromSettings(settings);
    final checkIns = history.checkIns;
    final shown = checkIns.length > progressTdeeMaxCheckIns
        ? checkIns.sublist(checkIns.length - progressTdeeMaxCheckIns)
        : checkIns;
    final runEnd = resolveCalorieGoalRunEndDate(settings: settings, day: today);
    return ProgressTdee(
      startTdeeKcal: history.startTdeeKcal,
      checkIns: shown,
      nextCheckInDay: nextDiaryDay(runEnd),
      isCheckInOpen: settings.pendingWeeklyCheckIn != null,
    );
  }

  /// TDEE of the calculator at the start of the goal.
  final double? startTdeeKcal;

  /// The latest confirmed check-ins, oldest first.
  final List<CalorieTdeeCheckIn> checkIns;

  /// Day on which the next check-in is due.
  final DateTime nextCheckInDay;

  /// Whether a check-in waits for the user's decision.
  final bool isCheckInOpen;

  /// The TDEE in effect now, or `null` before any value is known.
  double? get currentTdeeKcal => checkIns.lastOrNull?.tdeeKcal ?? startTdeeKcal;

  /// Change of the latest check-in against the value before it.
  double? get lastChangeKcal {
    final latest = checkIns.lastOrNull;
    if (latest == null) return null;
    final previous = checkIns.length > 1
        ? checkIns[checkIns.length - 2].tdeeKcal
        : startTdeeKcal;
    return previous == null ? null : latest.tdeeKcal - previous;
  }
}
