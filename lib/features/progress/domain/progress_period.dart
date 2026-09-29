import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Which goals the Fortschritt tab covers.
enum ProgressScope {
  /// The current goal, from its start to today.
  goal,

  /// All goals, from the start of the first one to today.
  all,
}

/// Number of days that a chart covers at least, so a goal that just started
/// still shows a trend.
const int progressMinChartDays = 7;

/// Number of days before today that a period covers without any goal.
const int progressFallbackDays = 28;

/// The first day of a goal and its number among all goals, starting at 1.
typedef ProgressGoalStart = ({int number, DateTime day});

/// The days that the Fortschritt tab covers for one [ProgressScope].
@immutable
class ProgressPeriod {
  /// Creates a period.
  const new({required this.start, required this.goalStarts});

  /// Resolves the period of [scope] from the goals in [settings].
  factory of({
    required CalorieGoalSettings settings,
    required ProgressScope scope,
    required DateTime today,
  }) {
    final goals = CalorieTdeeHistory.perGoal(settings);
    final firstShown = switch (scope) {
      ProgressScope.goal => goals.length - 1,
      ProgressScope.all => 0,
    };
    final starts = <ProgressGoalStart>[
      for (final (index, goal) in goals.indexed)
        if (index >= firstShown && goal.startDay != null)
          (number: index + 1, day: goal.startDay!),
    ];
    return ProgressPeriod(
      start:
          starts.firstOrNull?.day ?? addDiaryDays(today, -progressFallbackDays),
      goalStarts: List<ProgressGoalStart>.unmodifiable(starts),
    );
  }

  /// First day of the period.
  final DateTime start;

  /// First day of each goal in the period, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// First day that a chart shows: [start], or earlier so that the chart
  /// covers at least [progressMinChartDays] days up to [today].
  DateTime chartStart(DateTime today) {
    final earliest = addDiaryDays(today, 1 - progressMinChartDays);
    return start.isAfter(earliest) ? earliest : start;
  }
}
