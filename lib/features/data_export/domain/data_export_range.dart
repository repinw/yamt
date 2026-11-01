import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

/// First and last local day of an export, both included.
typedef DataExportDays = ({DateTime from, DateTime to});

/// The period the user picked for an export.
@immutable
sealed class DataExportRange {
  const new();

  /// The days of this range for [today].
  DataExportDays resolve({
    required CalorieGoalSettings settings,
    required DateTime today,
  });
}

/// The days of the current goal, or of all goals, as in Fortschritt.
@immutable
final class DataExportGoalRange extends DataExportRange {
  /// Creates the range of the goal of [scope].
  const new(this.scope);

  /// [ProgressScope.goal], or [ProgressScope.all] for all data.
  final ProgressScope scope;

  @override
  DataExportDays resolve({
    required CalorieGoalSettings settings,
    required DateTime today,
  }) {
    final period = ProgressPeriod.of(
      settings: settings,
      scope: scope,
      today: today,
    );
    return (from: period.start, to: period.end);
  }

  @override
  bool operator ==(Object other) =>
      other is DataExportGoalRange && other.scope == scope;

  @override
  int get hashCode => scope.hashCode;
}

/// The days of the goals [first] to [last], numbered among all goals from
/// 1 as in Fortschritt; a number past the past goals is the current goal.
@immutable
final class DataExportGoalsRange extends DataExportRange {
  /// Creates the range of the goals [first] to [last].
  const new(this.first, this.last)
    : assert(first <= last, 'The first goal comes before the last.');

  /// Number of the first goal.
  final int first;

  /// Number of the last goal.
  final int last;

  /// Whether the goal [number] is in this range.
  bool contains(int number) => number >= first && number <= last;

  /// This range after a tap on the goal [number]: a goal outside is added
  /// with the goals in between, the first or last goal is taken off, and
  /// a tap on a goal inside ends the range there; null when the only goal
  /// is taken off.
  DataExportGoalsRange? toggle(int number) {
    if (!contains(number)) {
      return DataExportGoalsRange(
        number < first ? number : first,
        number > last ? number : last,
      );
    }
    if (first == last) return null;
    if (number == first) return DataExportGoalsRange(first + 1, last);
    if (number == last) return DataExportGoalsRange(first, last - 1);
    return DataExportGoalsRange(first, number);
  }

  @override
  DataExportDays resolve({
    required CalorieGoalSettings settings,
    required DateTime today,
  }) {
    ProgressPeriod period(int number) => ProgressPeriod.of(
      settings: settings,
      scope: ProgressPastGoalScope(number),
      today: today,
    );
    return (from: period(first).start, to: period(last).end);
  }

  @override
  bool operator ==(Object other) =>
      other is DataExportGoalsRange &&
      other.first == first &&
      other.last == last;

  @override
  int get hashCode => Object.hash(first, last);
}

/// The last [days] days up to today.
@immutable
final class DataExportLastDaysRange extends DataExportRange {
  /// Creates the range of the last [days] days.
  const new(this.days);

  /// Number of days, today included.
  final int days;

  /// The ranges offered as chips: 7 days, 4 weeks, 3 months.
  static const List<DataExportLastDaysRange> presets = [
    DataExportLastDaysRange(7),
    DataExportLastDaysRange(28),
    DataExportLastDaysRange(91),
  ];

  @override
  DataExportDays resolve({
    required CalorieGoalSettings settings,
    required DateTime today,
  }) {
    final to = normalizeLocalDay(today);
    return (from: addLocalDays(to, 1 - days), to: to);
  }

  @override
  bool operator ==(Object other) =>
      other is DataExportLastDaysRange && other.days == days;

  @override
  int get hashCode => days.hashCode;
}

/// Days the user picked from a calendar.
@immutable
final class DataExportCustomRange extends DataExportRange {
  /// Creates the range from [from] to [to].
  const new({required this.from, required this.to});

  /// First day.
  final DateTime from;

  /// Last day.
  final DateTime to;

  @override
  DataExportDays resolve({
    required CalorieGoalSettings settings,
    required DateTime today,
  }) => (from: normalizeLocalDay(from), to: normalizeLocalDay(to));

  @override
  bool operator ==(Object other) =>
      other is DataExportCustomRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
