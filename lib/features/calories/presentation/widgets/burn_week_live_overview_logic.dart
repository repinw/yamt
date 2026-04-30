import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolves live Burn Week metrics from real diary data.
BurnWeekMockMetrics resolveBurnWeekLiveMetrics({
  required DateTime now,
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview todayOverview,
  required DateTime currentWeekStartDate,
  required double previousWeekOverflowKcal,
  required double heartCreditKcal,
  required double plannedLaterTodayKcal,
  required double safeZoneMultiplier,
}) {
  final dayProgress = resolveBurnWeekCurrentDayProgress(now);
  final fallbackDailyGoalKcal = resolveBurnWeekMockGoalKcal(
    todayOverview.goalKcal,
  );
  final currentWeekGoalKcal = weekOverview.days.fold<double>(0, (sum, day) {
    if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
      return sum;
    }
    return sum + day.goalKcal;
  });
  final rawWeeklyGoalKcal = math.max<double>(
    fallbackDailyGoalKcal * burnWeekDaysPerWeek,
    currentWeekGoalKcal,
  );
  final adjustedWeeklyGoalKcal = math.max<double>(
    fallbackDailyGoalKcal,
    rawWeeklyGoalKcal + previousWeekOverflowKcal,
  );
  final dailyGoalKcal = adjustedWeeklyGoalKcal / burnWeekDaysPerWeek;
  final completedDaysCount = weekOverview.days
      .where(
        (day) =>
            !isBeforeBurnWeekDay(day.date, currentWeekStartDate) &&
            isBeforeBurnWeekDay(day.date, todayOverview.date),
      )
      .length;
  final elapsedWeekDays = completedDaysCount + dayProgress;
  final targetKcal = dailyGoalKcal * elapsedWeekDays;
  final consumedKcal =
      weekOverview.days.fold<double>(
        0,
        (sum, day) {
          if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
            return sum;
          }
          if (isSameDiaryDay(day.date, todayOverview.date)) {
            return sum +
                math.max<double>(0, day.totalKcal - plannedLaterTodayKcal);
          }
          return sum + day.totalKcal;
        },
      ) +
      heartCreditKcal;

  return BurnWeekMockMetrics(
    dailyGoalKcal: dailyGoalKcal,
    weeklyGoalKcal: adjustedWeeklyGoalKcal,
    usesFallbackGoal: todayOverview.goalKcal <= 0,
    paceRatio: (targetKcal / adjustedWeeklyGoalKcal).clamp(0.0, 1.0),
    targetKcal: targetKcal,
    consumedKcal: consumedKcal,
    safeZoneMinKcal: targetKcal - (dailyGoalKcal * safeZoneMultiplier),
    safeZoneMaxKcal: targetKcal + (dailyGoalKcal * safeZoneMultiplier),
    barMinKcal: 0,
    barMaxKcal: adjustedWeeklyGoalKcal,
    plannedLaterKcal: plannedLaterTodayKcal,
  );
}

/// Resolves future same-day logged kcal that should stay in shadow state.
double resolveBurnWeekPlannedLaterTodayKcal({
  required List<CalorieEntry> todayEntries,
  required DateTime now,
}) {
  return todayEntries.fold<double>(0, (sum, entry) {
    if (!entry.loggedAt.isAfter(now)) {
      return sum;
    }
    return sum + entry.totalKcal;
  });
}

/// Resolves current day progress from wall clock.
double resolveBurnWeekCurrentDayProgress(DateTime now) {
  final startOfDay = DateTime(now.year, now.month, now.day);
  final elapsedSeconds = now.difference(startOfDay).inSeconds;
  return (elapsedSeconds / (24 * 60 * 60)).clamp(0.0, 1.0);
}

/// Day compare helper for Burn Week date math.
bool isBeforeBurnWeekDay(DateTime left, DateTime right) {
  return normalizeDiaryDay(left).isBefore(normalizeDiaryDay(right));
}

/// Resolves carryover inside current Burn Week before today.
double resolveBurnWeekCarryoverBeforeTodayKcal({
  required CalorieWeekOverview weekOverview,
  required DateTime currentWeekStartDate,
  required DateTime today,
}) {
  return CalorieBudgetCalculator.calculateCarryover(
    weekOverview.days
        .where(
          (day) =>
              !isBeforeBurnWeekDay(day.date, currentWeekStartDate) &&
              isBeforeBurnWeekDay(day.date, today),
        )
        .map(
          (day) => CalorieCarryoverDay(
            goalKcal: day.baseGoalKcal,
            consumedKcal: day.totalKcal,
          ),
        ),
  );
}

/// Resolves overflow that should affect the current Burn Week only.
double resolveBurnWeekPreviousOverflowKcal({
  required double cycleCarryoverBeforeTodayKcal,
  required double currentWeekCarryoverBeforeTodayKcal,
  required int runWeekNumber,
}) {
  if (runWeekNumber <= burnWeekLearningRunWeekNumber) {
    return 0;
  }
  return cycleCarryoverBeforeTodayKcal - currentWeekCarryoverBeforeTodayKcal;
}

/// Resolves eatable activity bonus sum inside current Burn Week.
double resolveBurnWeekActivityBonusKcal({
  required CalorieWeekOverview weekOverview,
  required DateTime currentWeekStartDate,
  required List<AsyncValue<ResolvedCalorieGoalData>> resolvedGoalStates,
}) {
  var total = 0.0;
  for (var index = 0; index < resolvedGoalStates.length; index += 1) {
    final day = weekOverview.days[index];
    if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
      continue;
    }
    total += resolvedGoalStates[index].asData?.value.activityDeltaKcal ?? 0;
  }
  return total;
}

/// Formats signed kcal string.
String formatBurnWeekSignedKcal(
  double value,
  NumberFormat numberFormat,
  String kcalUnit,
) {
  final roundedValue = value.round();
  final sign = roundedValue > 0 ? '+' : '';
  return '$sign${numberFormat.format(roundedValue)} $kcalUnit';
}

/// Formats live Burn Week label from run week and current day.
String formatBurnWeekLiveWeekDayLabel({
  required DateTime currentDay,
  required DateTime currentWeekStartDate,
  required int runWeekNumber,
  required AppLocalizations l10n,
}) {
  final dayNumber =
      normalizeDiaryDay(
        currentDay,
      ).difference(normalizeDiaryDay(currentWeekStartDate)).inDays +
      1;
  return l10n.burnWeekWeekDayLabel(runWeekNumber, dayNumber);
}

/// Parses persisted Burn Week day key into a normalized day.
DateTime? tryParseBurnWeekDayKey(String? dayKey) {
  final normalizedDayKey = dayKey?.trim();
  if (normalizedDayKey == null || normalizedDayKey.isEmpty) {
    return null;
  }
  final parts = normalizedDayKey.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return normalizeDiaryDay(DateTime(year, month, day));
}

/// Whether a persisted week start still belongs to the active cycle.
bool shouldUseStoredBurnWeekStartDate({
  required DateTime storedWeekStartDate,
  required DateTime currentDay,
  required DateTime balanceStartDate,
}) {
  final normalizedStoredWeekStart = normalizeDiaryDay(storedWeekStartDate);
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  final normalizedBalanceStartDate = normalizeDiaryDay(balanceStartDate);
  return !normalizedStoredWeekStart.isAfter(normalizedCurrentDay) &&
      !normalizedStoredWeekStart.isBefore(normalizedBalanceStartDate);
}

/// Resolves live current Burn Week start date.
DateTime resolveBurnWeekLiveWeekStartDate({
  required DateTime currentDay,
  required DateTime balanceStartDate,
  required String? storedWeekStartDayKey,
}) {
  final storedWeekStartDate = tryParseBurnWeekDayKey(storedWeekStartDayKey);
  if (storedWeekStartDate != null &&
      shouldUseStoredBurnWeekStartDate(
        storedWeekStartDate: storedWeekStartDate,
        currentDay: currentDay,
        balanceStartDate: balanceStartDate,
      )) {
    return storedWeekStartDate;
  }
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  final elapsedDays = resolveBurnWeekLiveElapsedDays(
    currentDay: normalizedCurrentDay,
    balanceStartDate: balanceStartDate,
  );
  final dayOffset = elapsedDays % burnWeekDaysPerWeek;
  return normalizedCurrentDay.subtract(Duration(days: dayOffset));
}

/// Resolves sync anchor for current live Burn Week.
DateTime resolveBurnWeekLiveSyncWeekStartDate({
  required DateTime currentDay,
  required DateTime currentWeekStartDate,
}) {
  var syncWeekStartDate = normalizeDiaryDay(currentWeekStartDate);
  final normalizedCurrentDay = normalizeDiaryDay(currentDay);
  while (!normalizedCurrentDay.isBefore(
    syncWeekStartDate.add(
      const Duration(days: burnWeekDaysPerWeek),
    ),
  )) {
    syncWeekStartDate = syncWeekStartDate.add(
      const Duration(days: burnWeekDaysPerWeek),
    );
  }
  return syncWeekStartDate;
}

/// Resolves elapsed days from original balance start.
int resolveBurnWeekLiveElapsedDays({
  required DateTime currentDay,
  required DateTime balanceStartDate,
}) {
  return normalizeDiaryDay(
    currentDay,
  ).difference(normalizeDiaryDay(balanceStartDate)).inDays.clamp(0, 1000000);
}

/// Resolves whether tracking miss already happened this week.
bool resolveBurnWeekLiveMissedTrackingThisWeek({
  required CalorieWeekOverview weekOverview,
  required DateTime currentWeekStartDate,
  required DateTime today,
  required CalorieGoalSettings settings,
}) {
  return weekOverview.days.any((day) {
    final normalizedDay = normalizeDiaryDay(day.date);
    if (normalizedDay.isBefore(normalizeDiaryDay(currentWeekStartDate))) {
      return false;
    }
    if (!normalizedDay.isBefore(normalizeDiaryDay(today))) {
      return false;
    }
    if (settings.isSkippedIntakeDay(normalizedDay)) {
      return false;
    }
    return day.entryCount == 0;
  });
}

/// Resolves whether tracking was missed in a stored Burn Week window.
bool resolveBurnWeekLiveMissedTrackingForStoredWeek({
  required CalorieWeekConsumptionSnapshot storedWeekSnapshot,
  required DateTime storedWeekStartDate,
  required DateTime today,
  required CalorieGoalSettings settings,
}) {
  return storedWeekSnapshot.days.any((day) {
    final normalizedDay = normalizeDiaryDay(day.date);
    if (normalizedDay.isBefore(normalizeDiaryDay(storedWeekStartDate))) {
      return false;
    }
    if (!normalizedDay.isBefore(normalizeDiaryDay(today))) {
      return false;
    }
    if (settings.isSkippedIntakeDay(normalizedDay)) {
      return false;
    }
    return day.entryCount == 0;
  });
}

/// Formats live clock label.
String formatBurnWeekLiveClockTime(DateTime now) {
  return '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';
}
