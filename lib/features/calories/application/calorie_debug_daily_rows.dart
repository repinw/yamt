import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

bool _hasDebugGoalWindows(CalorieGoalSettings settings) {
  return settings.sortedGoalHistory.any(
    (entry) => entry.hasGoal && !entry.isWeeklyCheckIn,
  );
}

bool _isDebugGoalWindowDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  if (!_hasDebugGoalWindows(settings)) {
    return true;
  }
  return settings.countingGoalEntryForDay(day)?.hasGoal == true;
}

/// One `eaten_day` row per goal window day with the eaten kcal.
List<CalorieDebugDumpRow> calorieDebugDailyEatenRows({
  required List<CalorieEntry> entries,
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final kcalByDay = <DateTime, double>{};
  final entryCountByDay = <DateTime, int>{};
  for (final entry in entries) {
    final day = normalizeDiaryDay(entry.loggedAt.toLocal());
    kcalByDay[day] = (kcalByDay[day] ?? 0) + entry.totalKcal;
    entryCountByDay[day] = (entryCountByDay[day] ?? 0) + 1;
  }

  final rows = <CalorieDebugDumpRow>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    if (!_isDebugGoalWindowDay(settings: settings, day: day)) {
      continue;
    }
    final entryCount = entryCountByDay[day] ?? 0;
    rows.add(
      CalorieDebugDumpRow(
        sortAt: day,
        typeOrder: 1,
        cells: [
          formatCalorieDebugDay(day),
          '',
          'eaten_day',
          'eaten_total',
          formatCalorieDebugNumber(kcalByDay[day] ?? 0),
          '',
          '',
          '',
          '',
          '',
          '',
          'app',
          'entries=$entryCount',
        ],
      ),
    );
  }
  return rows;
}

/// One `weight` row per day with a manual weight or Health samples.
List<CalorieDebugDumpRow> calorieDebugDailyWeightRows({
  required List<HealthWeightSample> healthWeightSamples,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final healthWeightsByDay = <String, List<double>>{};
  final manualWeightByDay = <String, double>{};
  final daysByKey = <String, DateTime>{};
  for (final sample in healthWeightSamples) {
    final day = normalizeDiaryDay(sample.recordedAt);
    final key = diaryDayKey(day);
    daysByKey[key] = day;
    healthWeightsByDay.putIfAbsent(key, () => <double>[]).add(sample.weightKg);
  }
  for (final entry in manualWeightEntries) {
    final day = normalizeDiaryDay(entry.day);
    final key = diaryDayKey(day);
    daysByKey[key] = day;
    manualWeightByDay[key] = entry.weightKg;
  }

  final days = daysByKey.values.toList(growable: false)..sort();
  return [
    for (final day in days)
      if (!day.isBefore(startInclusive) &&
          day.isBefore(endExclusive) &&
          _isDebugGoalWindowDay(settings: settings, day: day))
        _dailyWeightRow(
          day: day,
          manualWeightKg: manualWeightByDay[diaryDayKey(day)],
          healthWeightsKg:
              healthWeightsByDay[diaryDayKey(day)] ?? const <double>[],
        ),
  ];
}

CalorieDebugDumpRow _weightRow({
  required DateTime sortAt,
  required String source,
  required double weightKg,
}) {
  return CalorieDebugDumpRow(
    sortAt: sortAt,
    typeOrder: 4,
    cells: [
      formatCalorieDebugDay(sortAt),
      formatCalorieDebugTime(sortAt),
      'weight',
      'body_weight',
      '',
      '',
      '',
      '',
      '',
      '',
      formatCalorieDebugNumber(weightKg),
      source,
      '',
    ],
  );
}

CalorieDebugDumpRow _dailyWeightRow({
  required DateTime day,
  required double? manualWeightKg,
  required List<double> healthWeightsKg,
}) {
  final weightKg = manualWeightKg ?? CalorieDomainMath.median(healthWeightsKg);
  final source = manualWeightKg == null ? 'health' : 'manual_fallback';
  return _weightRow(sortAt: day, source: source, weightKg: weightKg);
}

/// The kcal of the daily rows of [type] and [name] by diary day key.
Map<String, double> calorieDebugDailyRowKcalByDay({
  required List<CalorieDebugDumpRow> rows,
  required String type,
  required String name,
}) {
  return <String, double>{
    for (final row in rows)
      if (row.cells[2] == type && row.cells[3] == name)
        diaryDayKey(row.sortAt): _parseDebugNumber(row.cells[4]) ?? 0,
  };
}

/// The body weight of the daily weight rows by diary day key.
Map<String, double> calorieDebugDailyRowWeightByDay(
  List<CalorieDebugDumpRow> rows,
) {
  final weightByDay = <String, double>{};
  for (final row in rows) {
    if (row.cells[2] != 'weight' || row.cells[3] != 'body_weight') {
      continue;
    }
    final weightKg = _parseDebugNumber(row.cells[10]);
    if (weightKg != null) {
      weightByDay[diaryDayKey(row.sortAt)] = weightKg;
    }
  }
  return weightByDay;
}

double? _parseDebugNumber(String value) {
  if (value.isEmpty) {
    return null;
  }
  return double.tryParse(value);
}
