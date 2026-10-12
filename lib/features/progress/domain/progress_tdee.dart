import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

/// One chart day: the daily TDEE and the value that intake and weight trend
/// of that day imply, each `null` before the first goal.
typedef ProgressTdeeDay = ({
  DateTime day,
  double? tdeeKcal,
  double? measuredKcal,
});

/// The daily TDEE of a period with its check-ins and goal starts, and when
/// the next check-in is due.
@immutable
class ProgressTdee {
  /// Creates the TDEE progress.
  const new({
    required this.days,
    required this.checkInDays,
    required this.goalStarts,
    required this.runStartDay,
    required this.nextCheckInDay,
    required this.isCheckInOpen,
  });

  /// Resolves the TDEE progress of [period] from the daily analytics
  /// [points] and the check-ins in [settings].
  factory fromPoints({
    required CalorieGoalSettings settings,
    required ProgressPeriod period,
    required List<TdeeAnalyticsPoint> points,
    required DateTime today,
  }) {
    final chartStart = period.chartStart(today);
    final pointsByDay = {
      for (final point in points) diaryDayKey(point.day): point,
    };
    final runStart = resolveCalorieGoalRunStartDate(
      settings: settings,
      day: today,
    );
    return ProgressTdee(
      days: [
        for (var day = chartStart; !day.isAfter(today); day = nextDiaryDay(day))
          if (day.isBefore(period.start))
            (day: day, tdeeKcal: null, measuredKcal: null)
          else
            (
              day: day,
              tdeeKcal: pointsByDay[diaryDayKey(day)]?.learnedBaseTdeeKcal,
              measuredKcal: pointsByDay[diaryDayKey(day)]?.totalTdeeKcal,
            ),
      ],
      checkInDays: {
        for (final goal in CalorieTdeeHistory.perGoal(settings))
          for (final day in goal.checkInDays)
            if (!day.isBefore(chartStart)) day,
      },
      goalStarts: [
        for (final start in period.goalStarts)
          if (start.day.isAfter(chartStart)) start,
      ],
      runStartDay: runStart,
      nextCheckInDay: addDiaryDays(runStart, calorieGoalRunLengthDays),
      isCheckInOpen: settings.pendingWeeklyCheckIn != null,
    );
  }

  /// Days of the chart, oldest first, ending today.
  final List<ProgressTdeeDay> days;

  /// Days on which a confirmed check-in took effect.
  final Set<DateTime> checkInDays;

  /// First day of each goal in the chart after its first day, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// First day of the running week.
  final DateTime runStartDay;

  /// Day on which the next check-in is due.
  final DateTime nextCheckInDay;

  /// Whether a check-in waits for the user's decision.
  final bool isCheckInOpen;

  /// Today's TDEE, or `null` before the first goal.
  ///
  /// Today carries yesterday's estimate, because today's diary is not
  /// complete yet.
  double? get currentTdeeKcal => days.lastOrNull?.tdeeKcal;

  /// Change of the latest estimate against the one before it.
  double? get changeSinceYesterdayKcal =>
      days.isEmpty ? null : _changeSince(addDiaryDays(days.last.day, -2));

  /// Change since the estimate in effect when the running week started.
  double? get changeThisWeekKcal => _changeSince(previousDiaryDay(runStartDay));

  double? _changeSince(DateTime day) {
    final current = currentTdeeKcal;
    final before = days
        .where((entry) => entry.day == day)
        .firstOrNull
        ?.tdeeKcal;
    return current == null || before == null ? null : current - before;
  }
}
