import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Stable hash for weekly check-in calculation inputs.
String weeklyCheckInInputHash({
  required PendingCalorieGoalWeeklyCheckIn weeklyCheckIn,
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyLearningSeed previousLearningSeed,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
  required CalorieWeeklyCheckInWeightData weightData,
  required Map<String, int> activeKcalByDay,
  required Set<String> heartDayKeys,
}) {
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: weeklyCheckIn.windowEndDate,
  );
  final buffer = StringBuffer()
    ..write('weekly-checkin-v2')
    ..write('|window=')
    ..write(
      calorieWeeklyCheckInWindowKey(
        weeklyCheckIn.windowStartDate,
        weeklyCheckIn.windowEndDate,
      ),
    )
    ..write('|learning=')
    ..write(diaryDayKey(dates.learningStartDate))
    ..write(':')
    ..write(diaryDayKey(weeklyCheckIn.windowEndDate))
    ..write('|math=')
    ..write(settings.calorieMathVersion)
    ..write('|prevGoal=')
    ..write(_hashDouble(previousLearningSeed.previousGoalKcal))
    ..write('|prevTdee=')
    ..write(_hashDouble(previousLearningSeed.previousLearnedTdeeKcal))
    ..write('|mode=')
    ..write(calculatorProfile?.goalMode.name ?? CalorieGoalMode.maintain.name)
    ..write('|speed=')
    ..write(_hashDouble(calculatorProfile?.goalSpeedKgPerWeek ?? 0));

  for (final day in dates.learningDays) {
    final dayKey = diaryDayKey(day);
    final entries = calorieEntriesByDay[dayKey] ?? const <CalorieEntry>[];
    final isHeartDay = heartDayKeys.contains(dayKey);
    buffer
      ..write('|day=')
      ..write(dayKey)
      ..write(':heart=')
      ..write(isHeartDay)
      ..write(':skipped=')
      ..write(settings.isSkippedIntakeDay(day));
    if (!isHeartDay) {
      buffer
        ..write(':count=')
        ..write(entries.length)
        ..write(':kcal=')
        ..write(_hashDouble(sumCalorieEntryKcal(entries)))
        ..write(':active=')
        ..write(activeKcalByDay[dayKey] ?? 0);
    }
  }

  for (final point in weightData.weightPoints) {
    buffer
      ..write('|weight=')
      ..write(point.dayIndex)
      ..write(':')
      ..write(_hashDouble(point.weightKg));
  }

  return 'v2:${_fnv1a32(buffer.toString())}';
}

String _hashDouble(double value) {
  return value.toStringAsFixed(4);
}

String _fnv1a32(String input) {
  const offsetBasis = 0x811c9dc5;
  const prime = 0x01000193;
  var hash = offsetBasis;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * prime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
