import 'package:yamt/features/calories/application/calorie_debug_daily_rows.dart';
import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/calorie_debug_week_tdee.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// A start and a summary row for each 7-day week of each goal.
List<CalorieDebugDumpRow> calorieDebugGoalWeekRows({
  required CalorieGoalSettings settings,
  required List<CalorieDebugDumpRow> rows,
  required DateTime startInclusive,
  required DateTime endExclusive,
  required Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final goalEntries = _debugGoalEntries(settings);
  if (goalEntries.isEmpty) {
    return const <CalorieDebugDumpRow>[];
  }

  final eatenKcalByDay = calorieDebugDailyRowKcalByDay(
    rows: rows,
    type: 'eaten_day',
    name: 'eaten_total',
  );
  final weightByDay = calorieDebugDailyRowWeightByDay(rows);
  final weekRows = <CalorieDebugDumpRow>[];

  for (var index = 0; index < goalEntries.length; index += 1) {
    final goalEntry = goalEntries[index];
    final goalStart = normalizeDiaryDay(goalEntry.effectiveCountingStartDate);
    final nextGoalStart = index + 1 < goalEntries.length
        ? normalizeDiaryDay(goalEntries[index + 1].effectiveCountingStartDate)
        : endExclusive;
    final goalEndExclusive = nextGoalStart.isBefore(endExclusive)
        ? nextGoalStart
        : endExclusive;

    var weekStart = goalStart;
    var weekNumber = 1;
    while (weekStart.isBefore(goalEndExclusive)) {
      final nextWeekStart = addDiaryDays(weekStart, 7);
      final weekEndExclusive = nextWeekStart.isBefore(goalEndExclusive)
          ? nextWeekStart
          : goalEndExclusive;
      if (!weekEndExclusive.isAfter(startInclusive)) {
        weekStart = nextWeekStart;
        weekNumber += 1;
        continue;
      }

      weekRows
        ..add(
          _weekStartRow(
            settings: settings,
            goalEntry: goalEntry,
            weekStart: weekStart,
            weekEndExclusive: weekEndExclusive,
            weekNumber: weekNumber,
            learnedTdeeByWeekStart: learnedTdeeByWeekStart,
          ),
        )
        ..add(
          _weekSummaryRow(
            settings: settings,
            weekStart: weekStart,
            weekEndExclusive: weekEndExclusive,
            weekNumber: weekNumber,
            eatenKcalByDay: eatenKcalByDay,
            weightByDay: weightByDay,
          ),
        );

      weekStart = nextWeekStart;
      weekNumber += 1;
    }
  }

  return List<CalorieDebugDumpRow>.unmodifiable(weekRows);
}

/// The diary day keys where a new goal week starts.
Set<String> calorieDebugGoalWeekSeparatorDays({
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final goalEntries = _debugGoalEntries(settings);
  final separatorDays = <String>{};
  for (var index = 0; index < goalEntries.length; index += 1) {
    final goalStart = normalizeDiaryDay(
      goalEntries[index].effectiveCountingStartDate,
    );
    final nextGoalStart = index + 1 < goalEntries.length
        ? normalizeDiaryDay(goalEntries[index + 1].effectiveCountingStartDate)
        : endExclusive;
    final goalEndExclusive = nextGoalStart.isBefore(endExclusive)
        ? nextGoalStart
        : endExclusive;

    for (
      var day = addDiaryDays(goalStart, 7);
      day.isBefore(goalEndExclusive);
      day = addDiaryDays(day, 7)
    ) {
      if (!day.isBefore(startInclusive)) {
        separatorDays.add(diaryDayKey(day));
      }
    }
  }
  return separatorDays;
}

List<CalorieGoalHistoryEntry> _debugGoalEntries(CalorieGoalSettings settings) {
  final entries =
      settings.sortedGoalHistory
          .where((entry) => entry.hasGoal && !entry.isWeeklyCheckIn)
          .toList(growable: false)
        ..sort((left, right) {
          final byStart = left.effectiveCountingStartDate.compareTo(
            right.effectiveCountingStartDate,
          );
          if (byStart != 0) {
            return byStart;
          }
          return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
        });
  return List<CalorieGoalHistoryEntry>.unmodifiable(entries);
}

CalorieDebugDumpRow _weekStartRow({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required DateTime weekStart,
  required DateTime weekEndExclusive,
  required int weekNumber,
  required Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final tdeeData = resolveCalorieDebugWeekTdeeData(
    settings: settings,
    goalEntry: goalEntry,
    weekStart: weekStart,
    learnedTdeeByWeekStart: learnedTdeeByWeekStart,
  );
  final range =
      '${diaryDayKey(weekStart)}'
      '..${diaryDayKey(previousDiaryDay(weekEndExclusive))}';
  return CalorieDebugDumpRow(
    sortAt: weekStart,
    typeOrder: 0,
    cells: [
      formatCalorieDebugDay(weekStart),
      '',
      'week',
      'week_${weekNumber}_start',
      formatCalorieDebugNumber(tdeeData.tdeeKcal),
      '',
      '',
      '',
      '',
      '',
      '',
      'app',
      [
        'week=$weekNumber',
        'range=$range',
        'tdee_source=${tdeeData.source}',
        'tdee=${formatCalorieDebugNumber(tdeeData.tdeeKcal)}',
        'used=${tdeeData.used}',
      ].join('; '),
    ],
  );
}

CalorieDebugDumpRow _weekSummaryRow({
  required CalorieGoalSettings settings,
  required DateTime weekStart,
  required DateTime weekEndExclusive,
  required int weekNumber,
  required Map<String, double> eatenKcalByDay,
  required Map<String, double> weightByDay,
}) {
  final days = _buildExclusiveDays(
    startDate: weekStart,
    endExclusive: weekEndExclusive,
  );
  final calculatedGoalTotal = days.fold<double>(
    0,
    (sum, day) => sum + settings.goalKcalForDay(day),
  );
  final eatenTotal = _sumDailyValues(days, eatenKcalByDay);
  final weights = [
    for (final day in days)
      if (weightByDay[diaryDayKey(day)] != null)
        (day: day, weightKg: weightByDay[diaryDayKey(day)]!),
  ];
  final startWeight = weights.isEmpty ? null : weights.first.weightKg;
  final endWeight = weights.isEmpty ? null : weights.last.weightKg;
  final weightChange = startWeight == null || endWeight == null
      ? null
      : endWeight - startWeight;
  final summaryDay = previousDiaryDay(weekEndExclusive);
  final range =
      '${diaryDayKey(weekStart)}'
      '..${diaryDayKey(summaryDay)}';
  final sortAt = summaryDay.add(
    const Duration(hours: 23, minutes: 59, seconds: 58),
  );

  return CalorieDebugDumpRow(
    sortAt: sortAt,
    typeOrder: 80,
    cells: [
      formatCalorieDebugDay(sortAt),
      formatCalorieDebugTime(sortAt),
      'week',
      'week_${weekNumber}_summary',
      formatCalorieDebugNumber(calculatedGoalTotal),
      '',
      '',
      '',
      '',
      '',
      formatCalorieDebugNumber(endWeight),
      'app',
      [
        'week=$weekNumber',
        'range=$range',
        'days=${days.length}',
        calorieDebugNamedNumber('calculated_goal_total', calculatedGoalTotal),
        'eaten_total=${formatCalorieDebugNumber(eatenTotal)}',
        calorieDebugNamedNumber(
          'eaten_minus_goal',
          eatenTotal - calculatedGoalTotal,
        ),
        'start_weight=${formatCalorieDebugNumber(startWeight)}',
        'end_weight=${formatCalorieDebugNumber(endWeight)}',
        'weight_change=${formatCalorieDebugNumber(weightChange)}',
      ].join('; '),
    ],
  );
}

double _sumDailyValues(List<DateTime> days, Map<String, double> valuesByDay) {
  return days.fold<double>(
    0,
    (sum, day) => sum + (valuesByDay[diaryDayKey(day)] ?? 0),
  );
}

List<DateTime> _buildExclusiveDays({
  required DateTime startDate,
  required DateTime endExclusive,
}) {
  final normalizedStartDate = normalizeDiaryDay(startDate);
  final normalizedEndExclusive = normalizeDiaryDay(endExclusive);
  return <DateTime>[
    for (
      var day = normalizedStartDate;
      day.isBefore(normalizedEndExclusive);
      day = nextDiaryDay(day)
    )
      day,
  ];
}
