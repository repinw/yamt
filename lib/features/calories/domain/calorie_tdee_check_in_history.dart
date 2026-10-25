import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';

/// One goal: its first counted day and the days of its confirmed weekly
/// check-ins, oldest first.
@immutable
class CalorieTdeeHistory {
  /// Creates a goal history.
  const new({required this.startDay, required this.checkInDays});

  /// Resolves one history per goal in [settings], oldest goal first.
  ///
  /// A goal starts with every entry that sets a goal outside a weekly
  /// check-in. A check-in counts only after the user decided on it: an entry
  /// for the window of the still pending check-in is left out.
  static List<CalorieTdeeHistory> perGoal(CalorieGoalSettings settings) {
    final pending = settings.pendingWeeklyCheckIn;
    final pendingStart = pending == null
        ? null
        : localDayKey(pending.windowStartDate);
    final histories = <CalorieTdeeHistory>[];
    CalorieGoalHistoryEntry? goal;
    var checkInDays = <DateTime>[];

    void close() {
      final start = goal;
      if (start == null) return;
      histories.add(
        CalorieTdeeHistory(
          startDay: normalizeLocalDay(start.effectiveCountingStartDate),
          checkInDays: List<DateTime>.unmodifiable(checkInDays),
        ),
      );
    }

    for (final entry in settings.sortedGoalHistory) {
      if (entry.hasGoal && entry.source != CalorieGoalSource.weeklyCheckIn) {
        close();
        goal = entry;
        checkInDays = <DateTime>[];
        continue;
      }
      if (goal != null && _isConfirmedCheckIn(entry, pendingStart)) {
        checkInDays.add(normalizeLocalDay(entry.effectiveDate));
      }
    }
    close();
    return List<CalorieTdeeHistory>.unmodifiable(histories);
  }

  /// First counted day of the goal.
  final DateTime startDay;

  /// Days on which a confirmed check-in took effect, oldest first.
  final List<DateTime> checkInDays;
}

bool _isConfirmedCheckIn(
  CalorieGoalHistoryEntry entry,
  String? pendingWindowStartKey,
) {
  final snapshot = entry.weeklyCheckInSnapshot;
  return entry.source == CalorieGoalSource.weeklyCheckIn &&
      snapshot != null &&
      localDayKey(snapshot.windowStartDate) != pendingWindowStartKey;
}
