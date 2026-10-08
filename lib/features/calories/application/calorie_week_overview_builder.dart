import 'package:yamt/features/calories/application/calorie_week_cycle_totals.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Builds the week overview of the visible days [overviews], whose last day
/// is the selected day.
///
/// The carryover comes from [historicalEntries] between
/// [carryoverStartDate] and the first visible day. [realToday] is today;
/// [readClosedDay] is asked only for tomorrow, so a bad stored value cannot
/// break the other days.
CalorieWeekOverview buildCalorieWeekOverview({
  required CalorieGoalSettings settings,
  required List<CalorieWeekDayOverview> overviews,
  required DateTime realToday,
  required DateTime balanceStartDate,
  required DateTime carryoverStartDate,
  required List<CalorieEntry> historicalEntries,
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
      .map((day) => settings.goalKcalForDay(normalizeDiaryDay(day)))
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
  final todayBaseGoalKcal = overviews.last.baseGoalKcal > 0
      ? overviews.last.baseGoalKcal
      : overviews.last.goalKcal;
  final distributedCarryoverKcal = CalorieBudgetCalculator.distributeCarryover(
    carryoverKcal: cycleTotals.carryoverBeforeTodayKcal,
    remainingDays: resolveRemainingCalorieGoalRunDays(
      settings: settings,
      day: today,
    ),
    baseGoalKcal: todayBaseGoalKcal,
  );
  // Tomorrow can plan with today's carryover once today is closed, unless
  // it starts a new run or is a pause day.
  final previousDayCarryoverKcal =
      isSameDiaryDay(today, nextDiaryDay(realToday)) &&
          isBeforeDay(carryoverStartDate, today) &&
          !overviews.last.isPauseDay
      ? distributedCarryoverKcal
      : null;
  // Only tomorrow reads the closed day, so a bad stored value cannot break
  // the other days.
  final closedDay = previousDayCarryoverKcal == null ? null : readClosedDay();
  final isPreviousDayClosed =
      closedDay != null && isSameDiaryDay(closedDay, realToday);
  // Any other future day gets no carryover: the days before it are not
  // finished yet, so a carryover from them would be made up.
  final carryoverBeforeTodayKcal =
      DiaryDayStatus.of(
        day: today,
        today: realToday,
        isPreviousDayClosed: isPreviousDayClosed,
      ).isPlanned
      ? 0.0
      : distributedCarryoverKcal;
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
  );
}
