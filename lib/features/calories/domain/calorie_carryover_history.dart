import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Builds normalized diary days used for carryover history.
List<DateTime> buildCalorieCarryoverDateRange({
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <DateTime>[];
  }

  final days = <DateTime>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(normalizeDiaryDay(endExclusive));
    day = nextDiaryDay(day)
  ) {
    days.add(day);
  }
  return List<DateTime>.unmodifiable(days);
}

/// Builds carryover day snapshots from resolved goals and logged entries.
List<CalorieCarryoverDay> buildCalorieCarryoverDays({
  required List<DateTime> days,
  required List<double> goalKcals,
  required Map<String, List<CalorieEntry>> entriesByDay,
}) {
  final carryoverDays = <CalorieCarryoverDay>[];
  for (var index = 0; index < days.length; index += 1) {
    final day = days[index];
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    final consumedKcal = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    carryoverDays.add(
      CalorieCarryoverDay(
        goalKcal: goalKcals[index],
        consumedKcal: consumedKcal,
      ),
    );
  }
  return List<CalorieCarryoverDay>.unmodifiable(carryoverDays);
}
