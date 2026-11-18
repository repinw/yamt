import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_week_balance_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_cycle_totals.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

/// Builds the week overview of the visible days [overviews], whose last day
/// is the selected day.
///
/// The week balance of the selected day's run gives its carryover; the days
/// of the run after the selected day come from [laterEntries]. The totals
/// come from [historicalEntries] between [carryoverStartDate] and the first
/// visible day. [realToday] is today; [readClosedDay] is asked only in the
/// mode that carries over, where a closed today counts as a finished day for
/// every day after it.
CalorieWeekOverview buildCalorieWeekOverview({
  required CalorieGoalSettings settings,
  required List<CalorieWeekDayOverview> overviews,
  required DateTime realToday,
  required DateTime balanceStartDate,
  required DateTime carryoverStartDate,
  required List<CalorieEntry> historicalEntries,
  required List<CalorieEntry> laterEntries,
  required DateTime? Function() readClosedDay,
}) {
  final today = overviews.last.date;
  final visibleWindowStart = overviews.first.date;
  final historicalEntriesByDay = historicalEntries.groupByDiaryDayKey();
  final historicalDays = buildCalorieCarryoverDateRange(
    startInclusive: carryoverStartDate,
    endExclusive: visibleWindowStart,
  );
  final historicalGoalKcals = historicalDays
      .map((day) => settings.goalKcalForDay(normalizeLocalDay(day)))
      .toList(growable: false);
  final historicalCarryoverDays = buildCalorieCarryoverDays(
    days: historicalDays,
    goalKcals: historicalGoalKcals,
    entriesByDay: historicalEntriesByDay,
  );
  final cycleTotals = calculateCalorieWeekCycleTotals(
    cycleStartDate: carryoverStartDate,
    today: today,
    historicalCarryoverDays: historicalCarryoverDays,
    historicalDays: historicalDays,
    settings: settings,
    visibleOverviews: overviews,
  );
  final hasActiveGoalToday = settings.goalEntryForDay(today)?.hasGoal == true;
  final hasCountedGoalToday = settings.countingGoalEntryForDay(today) != null;
  final nextGoalStartDate = settings.nextGoalStartAfterDay(today);
  final goalStartsInFuture = !hasCountedGoalToday && nextGoalStartDate != null;
  final futureGoalKcal = hasActiveGoalToday
      ? settings.goalKcalForDay(today)
      : nextGoalStartDate == null
      ? null
      : settings.goalKcalForDay(nextGoalStartDate);
  final closedDay = settings.weekBalanceMode.carriesOver
      ? readClosedDay()
      : null;
  // A close does not count while tomorrow is a pause day: that day takes
  // no carryover. The stored value stays, so the close counts again once
  // tomorrow is a normal day.
  final isTodayClosed =
      closedDay != null &&
      isSameLocalDay(closedDay, realToday) &&
      !settings.isPauseDay(nextLocalDay(realToday));
  final weekBalance = buildCalorieWeekBalance(
    settings: settings,
    overviews: overviews,
    realToday: realToday,
    laterEntries: laterEntries,
    isTodayClosed: isTodayClosed,
  );
  final carryoverBeforeTodayKcal =
      weekBalance?.dayOf(today)?.carryoverKcal ?? 0.0;
  // In the mode that carries over, today can be closed for tomorrow, unless
  // tomorrow starts a new run or is a pause day.
  final previousDayCarryoverKcal =
      settings.weekBalanceMode.carriesOver &&
          isSameLocalDay(today, nextLocalDay(realToday)) &&
          isBeforeDay(carryoverStartDate, today) &&
          !overviews.last.isPauseDay
      ? carryoverBeforeTodayKcal
      : null;
  final isPreviousDayClosed = previousDayCarryoverKcal != null && isTodayClosed;
  final todayFlexibleGoalKcal =
      overviews.last.goalKcal + carryoverBeforeTodayKcal;
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable(overviews),
    totalConsumedKcal: cycleTotals.totalConsumedKcal,
    totalGoalKcal: cycleTotals.totalGoalKcal,
    remainingKcal: cycleTotals.totalGoalKcal - cycleTotals.totalConsumedKcal,
    balanceStartDate: balanceStartDate,
    carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
    previousDayCarryoverKcal: previousDayCarryoverKcal,
    isPreviousDayClosed: isPreviousDayClosed,
    weekBalance: weekBalance,
  );
}
