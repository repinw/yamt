import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

/// Calculates rolling cycle totals and carryover before today.
({
  double totalConsumedKcal,
  double totalGoalKcal,
  double carryoverBeforeTodayKcal,
})
calculateCalorieWeekCycleTotals({
  required DateTime cycleStartDate,
  required DateTime today,
  required List<CalorieCarryoverDay> historicalCarryoverDays,
  required List<DateTime> historicalDays,
  required CalorieGoalSettings settings,
  required List<CalorieWeekDayOverview> visibleOverviews,
}) {
  var totalConsumedKcal = 0.0;
  var totalGoalKcal = 0.0;
  var carryoverBeforeTodayKcal = 0.0;

  if (!cycleStartDate.isAfter(today)) {
    for (var index = 0; index < historicalCarryoverDays.length; index += 1) {
      final day = historicalCarryoverDays[index];
      final isPauseDay =
          index < historicalDays.length &&
          settings.isPauseDay(historicalDays[index]);
      final consumedKcal = isPauseDay ? day.goalKcal : day.consumedKcal;
      totalConsumedKcal += consumedKcal;
      totalGoalKcal += day.goalKcal;
      carryoverBeforeTodayKcal += day.goalKcal - consumedKcal;
    }

    for (final day in visibleOverviews) {
      if (isBeforeDay(day.date, cycleStartDate)) {
        continue;
      }
      totalConsumedKcal += day.countedTotalKcal;
      totalGoalKcal += day.goalKcal;
      if (isBeforeDay(day.date, today)) {
        carryoverBeforeTodayKcal += day.goalKcal - day.countedTotalKcal;
      }
    }
  }

  return (
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
  );
}

/// Returns true if [left] is strictly before [right] calendar date.
bool isBeforeDay(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isBefore(DateTime(right.year, right.month, right.day));
}
