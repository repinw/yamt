import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// One run: its first and last day, and its number in its goal, or `null`
/// for a block without a goal.
typedef ProgressWeightRunKey = ({DateTime start, DateTime end, int? number});

/// The run of every day from [start] to [today]: the 7-day runs of the
/// counting goals, and 7-day blocks without a number in the gaps between
/// them. A gap after a goal counts its blocks from its first day; a gap
/// at the start of the range counts them back from its last day.
Map<DateTime, ProgressWeightRunKey> progressWeightRunsByDay(
  CalorieGoalSettings settings,
  DateTime start,
  DateTime today,
) {
  final days = [
    for (var day = start; !day.isAfter(today); day = addDiaryDays(day, 1)) day,
  ];
  // shortcut: three goal history lookups per day; precompute per goal once
  // the "Alles" range spans years.
  final hasGoal = [
    for (final day in days) settings.countingGoalEntryForDay(day) != null,
  ];
  final runs = <DateTime, ProgressWeightRunKey>{};
  var index = 0;
  while (index < days.length) {
    var last = index;
    while (last + 1 < days.length && hasGoal[last + 1] == hasGoal[index]) {
      last++;
    }
    if (hasGoal[index]) {
      for (var at = index; at <= last; at++) {
        final day = days[at];
        // The run start is off midnight across a clock change.
        final runStart = normalizeDiaryDay(
          resolveCalorieGoalRunStartDate(settings: settings, day: day),
        );
        final runEnd = addDiaryDays(runStart, calorieGoalRunLengthDays - 1);
        runs[day] = (
          start: runStart,
          // A run that a gap cuts short ends with the goal.
          end: runEnd.isAfter(days[last]) ? days[last] : runEnd,
          number: resolveCalorieGoalRunNumber(settings: settings, day: day),
        );
      }
      index = last + 1;
      continue;
    }
    final gapStart = days[index];
    final gapEnd = days[last];
    for (var at = index; at <= last; at++) {
      final DateTime blockStart;
      final DateTime blockEnd;
      if (index > 0) {
        final offset = diaryDaysBetween(gapStart, days[at]);
        blockStart = addDiaryDays(
          gapStart,
          offset - offset % calorieGoalRunLengthDays,
        );
        final end = addDiaryDays(blockStart, calorieGoalRunLengthDays - 1);
        blockEnd = end.isAfter(gapEnd) ? gapEnd : end;
      } else {
        final offset = diaryDaysBetween(days[at], gapEnd);
        blockEnd = addDiaryDays(
          gapEnd,
          -(offset - offset % calorieGoalRunLengthDays),
        );
        final begin = addDiaryDays(blockEnd, 1 - calorieGoalRunLengthDays);
        blockStart = begin.isBefore(gapStart) ? gapStart : begin;
      }
      runs[days[at]] = (start: blockStart, end: blockEnd, number: null);
    }
    index = last + 1;
  }
  // A run ends where the next one starts, also when a new goal restarts the
  // runs mid-run.
  final starts = {for (final run in runs.values) run.start}
      .sorted((left, right) => left.compareTo(right));
  final nextStart = {
    for (final (index, start) in starts.indexed)
      if (index + 1 < starts.length) start: starts[index + 1],
  };
  return runs.map((day, run) {
    final next = nextStart[run.start];
    final cut = next == null ? null : addDiaryDays(next, -1);
    return MapEntry(
      day,
      cut != null && run.end.isAfter(cut)
          ? (start: run.start, end: cut, number: run.number)
          : run,
    );
  });
}
