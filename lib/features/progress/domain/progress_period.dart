import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_tdee_check_in_history.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';

/// Which goals the Fortschritt tab covers.
sealed class ProgressScope {
  const new();

  /// The current goal, from its start to today.
  static const ProgressScope goal = ProgressGoalScope._();

  /// All goals, from the start of the first one to today.
  static const ProgressScope all = ProgressAllScope._();

  /// The scope that [name] gives; all goals when [name] names none.
  static ProgressScope byName(String? name) {
    if (name == goal.name) return goal;
    final number = name != null && name.startsWith(_pastGoalPrefix)
        ? int.tryParse(name.substring(_pastGoalPrefix.length))
        : null;
    return number == null ? all : ProgressPastGoalScope(number);
  }

  /// Stable name of the scope, for keys and route parameters.
  String get name;
}

const _pastGoalPrefix = 'goal-';

/// The current goal, from its start to today.
final class ProgressGoalScope extends ProgressScope {
  const new _();

  @override
  String get name => 'goal';
}

/// All goals, from the start of the first one to today.
final class ProgressAllScope extends ProgressScope {
  const new _();

  @override
  String get name => 'all';
}

/// One goal before the current one, from its start to its last day.
@immutable
final class ProgressPastGoalScope extends ProgressScope {
  /// Creates the scope of the goal with [number] among all goals, from 1.
  const new(this.number);

  /// Number of the goal among all goals, starting at 1.
  final int number;

  @override
  String get name => '$_pastGoalPrefix$number';

  @override
  bool operator ==(Object other) =>
      other is ProgressPastGoalScope && other.number == number;

  @override
  int get hashCode => number.hashCode;
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
  const new({required this.start, required this.end, required this.goalStarts});

  /// Resolves the period of [scope] from the goals in [settings].
  ///
  /// A past goal covers the days that the goal menu shows for it: from its
  /// start to its end, at the latest today. A number that names no past goal
  /// covers the current goal.
  factory of({
    required CalorieGoalSettings settings,
    required ProgressScope scope,
    required DateTime today,
  }) {
    if (scope case ProgressPastGoalScope(:final number)) {
      // The combined goal comes first, then the goals newest first; the
      // newest one is the current goal.
      final cycles = TdeeCycleResolver.resolveGoalCycles(settings);
      if (number >= 1 && number <= cycles.length - 2) {
        final goal = cycles[cycles.length - number];
        final start = normalizeDiaryDay(goal.startDate);
        // A goal ended on the day the next one starts leaves that day to it.
        final beforeNext = previousDiaryDay(
          normalizeDiaryDay(cycles[cycles.length - number - 1].startDate),
        );
        var end = normalizeDiaryDay(goal.endDate ?? today);
        if (end.isAfter(beforeNext)) end = beforeNext;
        if (end.isAfter(today)) end = today;
        return ProgressPeriod(
          start: start,
          end: end.isBefore(start) ? start : end,
          goalStarts: List.unmodifiable([(number: number, day: start)]),
        );
      }
    }
    final goals = CalorieTdeeHistory.perGoal(settings);
    final current = goals.length - 1;
    final first = scope == ProgressScope.all ? 0 : current;
    final starts = List<ProgressGoalStart>.unmodifiable([
      for (final (index, goal) in goals.indexed)
        if (index >= first) (number: index + 1, day: goal.startDay),
    ]);
    final start =
        starts.firstOrNull?.day ?? addDiaryDays(today, -progressFallbackDays);
    return ProgressPeriod(start: start, end: today, goalStarts: starts);
  }

  /// First day of the period.
  final DateTime start;

  /// Last day of the period: today, or the last day of a past goal.
  final DateTime end;

  /// First day of each goal in the period, oldest first.
  final List<ProgressGoalStart> goalStarts;

  /// First day that a chart shows: [start], or earlier so that the chart
  /// covers at least [progressMinChartDays] days up to [end].
  DateTime get chartStart {
    final earliest = addDiaryDays(end, 1 - progressMinChartDays);
    return start.isAfter(earliest) ? earliest : start;
  }
}
