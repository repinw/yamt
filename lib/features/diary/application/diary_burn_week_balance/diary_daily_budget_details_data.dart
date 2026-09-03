import 'dart:math' as math;

import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';

/// One previous day's contribution to the carryover calculation.
class DiaryCarryoverDayDetail {
  /// Creates a carryover day detail.
  const DiaryCarryoverDayDetail({
    required this.date,
    required this.goalKcal,
    required this.consumedKcal,
    required this.differenceKcal,
    required this.isHeartDay,
  });

  /// Date of the previous day.
  final DateTime date;

  /// Canonical target for this day.
  final double goalKcal;

  /// Calories consumed (or counted) for this day.
  final double consumedKcal;

  /// Positive if calories were saved, negative if over budget.
  final double differenceKcal;

  /// Whether this day was protected by a spent heart.
  final bool isHeartDay;
}

/// Detailed breakdown of today's calorie budget and carryover origin.
class DiaryDailyBudgetDetailsData {
  /// Creates daily budget details data.
  const DiaryDailyBudgetDetailsData({
    required this.selectedDay,
    required this.baseGoalKcal,
    required this.carryoverKcal,
    required this.activityBonusKcal,
    required this.targetKcal,
    required this.eatenKcal,
    required this.dayLeftKcal,
    required this.isHeartDay,
    required this.totalCarryoverBeforeTodayKcal,
    required this.remainingRunDays,
    required this.previousDays,
    this.expectedActivityKcal = 0.0,
    this.todayActiveKcal = 0,
  });

  /// Builds budget details from week overview, day overview, and daily metrics.
  factory DiaryDailyBudgetDetailsData.from({
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required DiaryDailyBalanceMetrics metrics,
    required bool isHeartDay,
  }) {
    final selectedDate = normalizeDiaryDay(selectedDayOverview.date);
    final balanceStartDate = normalizeDiaryDay(weekOverview.balanceStartDate);

    final previousDays = <DiaryCarryoverDayDetail>[];
    var computedTotalCarryover = 0.0;

    for (final day in weekOverview.days) {
      final dayDate = normalizeDiaryDay(day.date);
      if (!dayDate.isBefore(selectedDate)) {
        continue;
      }
      if (dayDate.isBefore(balanceStartDate)) {
        continue;
      }
      final diff = day.goalKcal - day.countedTotalKcal;
      computedTotalCarryover += diff;
      previousDays.add(
        DiaryCarryoverDayDetail(
          date: day.date,
          goalKcal: day.goalKcal,
          consumedKcal: day.countedTotalKcal,
          differenceKcal: diff,
          isHeartDay: day.isHeartDay,
        ),
      );
    }

    final remainingRunDays = math.max(1, 7 - previousDays.length);
    final totalCarryover = previousDays.isNotEmpty
        ? computedTotalCarryover
        : (metrics.carryoverKcal * remainingRunDays);

    return DiaryDailyBudgetDetailsData(
      selectedDay: selectedDayOverview.date,
      baseGoalKcal: metrics.baseGoalKcal,
      carryoverKcal: metrics.carryoverKcal,
      activityBonusKcal: metrics.activitySegmentKcal,
      targetKcal: metrics.targetKcal,
      eatenKcal: metrics.eatenKcal,
      dayLeftKcal: metrics.dayLeftKcal,
      isHeartDay: isHeartDay,
      totalCarryoverBeforeTodayKcal: totalCarryover,
      remainingRunDays: remainingRunDays,
      previousDays: List<DiaryCarryoverDayDetail>.unmodifiable(previousDays),
      expectedActivityKcal: metrics.expectedActivityKcal,
      todayActiveKcal: metrics.todayActiveKcal,
    );
  }

  /// Selected diary day.
  final DateTime selectedDay;

  /// Base daily target before activity and carryover adjustments.
  final double baseGoalKcal;

  /// Distributed carryover adjustment applied to today.
  final double carryoverKcal;

  /// Activity bonus calories earned today.
  final double activityBonusKcal;

  /// Effective daily target (baseGoal + carryover + activity).
  final double targetKcal;

  /// Calories eaten so far today.
  final double eatenKcal;

  /// Calories remaining today.
  final double dayLeftKcal;

  /// Whether today is protected by a spent heart.
  final bool isHeartDay;

  /// Total carryover sum accumulated from previous finished days in this run.
  final double totalCarryoverBeforeTodayKcal;

  /// Number of days remaining in this 7-day run, including today.
  final int remainingRunDays;

  /// Detailed contributions from each finished day in this run.
  final List<DiaryCarryoverDayDetail> previousDays;

  /// Expected baseline active calories for today.
  final double expectedActivityKcal;

  /// Tracked active calories on this day.
  final int todayActiveKcal;

  /// Whether expected baseline activity is configured for this day.
  bool get hasExpectedActivity => expectedActivityKcal.round() > 0;

  /// Base goal without the expected baseline activity.
  double get baseGoalWithoutActivityKcal =>
      math.max(0, baseGoalKcal - expectedActivityKcal);

  /// Additional sport / activity calories exceeding the baseline.
  double get extraSportKcal => activityBonusKcal;

  /// Whether the user exceeded the expected activity through sports.
  bool get hasExceededActivity => extraSportKcal.round() > 0;
}
