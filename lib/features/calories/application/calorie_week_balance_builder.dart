import 'package:collection/collection.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';

/// The week balance of the goal run that holds the last day of [overviews],
/// or null when that day has no counting goal, so no run.
///
/// The days of the run up to the selected day come from [overviews], the
/// rolling window that ends on it; [laterEntries] are the entries of the
/// run's days after it. [realToday] is today; with [isTodayClosed] it counts
/// as a finished day for the days after it.
///
/// A new goal ends the run of the old one the day before it takes effect,
/// even when it counts only from a later day (the days between belong to no
/// run): the run's budgets stay the ones of the full run and the balance
/// holds only its own days.
WeekBalance? buildCalorieWeekBalance({
  required CalorieGoalSettings settings,
  required List<CalorieWeekDayOverview> overviews,
  required DateTime realToday,
  required List<CalorieEntry> laterEntries,
  bool isTodayClosed = false,
}) {
  final selectedDay = overviews.last.date;
  if (settings.countingGoalEntryForDay(selectedDay) == null) {
    return null;
  }
  final runStart = resolveCalorieGoalRunStartDate(
    settings: settings,
    day: selectedDay,
  );
  final laterByDay = laterEntries.groupByDiaryDayKey();
  WeekBalanceDayInput inputOf(DateTime date) {
    final overview = overviews.firstWhereOrNull(
      (day) => isSameLocalDay(day.date, date),
    );
    final entries = laterByDay[localDayKey(date)] ?? const <CalorieEntry>[];
    return (
      date: date,
      goalKcal: settings.goalKcalForDay(date),
      eatenKcal:
          overview?.totalKcal ??
          entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal),
      hasEntries: overview?.hasEntries ?? entries.isNotEmpty,
      isPauseDay: settings.isPauseDay(date),
    );
  }

  final fullRun = WeekBalance.resolve(
    mode: settings.weekBalanceMode,
    weightGoal:
        settings.goalEntryForDay(selectedDay)?.calculatorProfile?.goalMode ??
        settings.calculatorProfile?.goalMode ??
        CalorieGoalMode.maintain,
    today: realToday,
    isTodayClosed: isTodayClosed,
    days: [
      for (var index = 0; index < calorieGoalRunLengthDays; index += 1)
        inputOf(addLocalDays(runStart, index)),
    ],
  );
  final nextGoalEffective = settings.nextGoalEffectiveDateAfterDay(selectedDay);
  if (nextGoalEffective == null) {
    return fullRun;
  }
  return WeekBalance(
    mode: fullRun.mode,
    weightGoal: fullRun.weightGoal,
    days: List<WeekBalanceDay>.unmodifiable(
      fullRun.days.where((day) => day.date.isBefore(nextGoalEffective)),
    ),
  );
}
