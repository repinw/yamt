import 'dart:math' as math;

import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// One previous day's contribution to the carryover calculation.
class DiaryCarryoverDayDetail {
  /// Creates a carryover day detail.
  const DiaryCarryoverDayDetail({
    required this.date,
    required this.goalKcal,
    required this.consumedKcal,
    required this.differenceKcal,
    required this.isPauseDay,
  });

  /// Date of the previous day.
  final DateTime date;

  /// Canonical target for this day.
  final double goalKcal;

  /// Calories consumed (or counted) for this day.
  final double consumedKcal;

  /// Positive if calories were saved, negative if over budget.
  final double differenceKcal;

  /// Whether this day was a pause day.
  final bool isPauseDay;
}

/// Detailed breakdown of today's calorie budget and carryover origin.
class DiaryDailyBudgetDetailsData {
  /// Creates daily budget details data.
  const DiaryDailyBudgetDetailsData({
    required this.selectedDay,
    required this.baseGoalKcal,
    required this.carryoverKcal,
    required this.targetKcal,
    required this.eatenKcal,
    required this.dayLeftKcal,
    required this.isPauseDay,
    required this.totalCarryoverBeforeTodayKcal,
    required this.remainingRunDays,
    required this.previousDays,
    this.unadjustedBaseGoalKcal,
    this.cyclingAdjustmentKcal = 0.0,
  });

  /// Builds budget details from week overview, day overview, and daily metrics.
  factory DiaryDailyBudgetDetailsData.from({
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required DiaryDailyBalanceMetrics metrics,
    required bool isPauseDay,
    required DateTime carryoverStartDate,
  }) => _DiaryDailyBudgetDetailsResolver(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    metrics: metrics,
    isPauseDay: isPauseDay,
    carryoverStartDate: carryoverStartDate,
  ).resolve();

  /// Selected diary day.
  final DateTime selectedDay;

  /// Unadjusted base daily target before calorie cycling (weekly average).
  final double? unadjustedBaseGoalKcal;

  /// Calorie cycling adjustment for this day (positive for training, negative
  /// for rest).
  final double cyclingAdjustmentKcal;

  /// Base daily target before carryover adjustments.
  final double baseGoalKcal;

  /// Distributed carryover adjustment applied to today.
  final double carryoverKcal;

  /// Effective daily target (base goal plus carryover).
  final double targetKcal;

  /// Calories eaten so far today.
  final double eatenKcal;

  /// Calories remaining today.
  final double dayLeftKcal;

  /// Whether today is a pause day.
  final bool isPauseDay;

  /// Total carryover sum accumulated from previous finished days in this run.
  final double totalCarryoverBeforeTodayKcal;

  /// Number of days remaining in this 7-day run, including today.
  final int remainingRunDays;

  /// Detailed contributions from each finished day in this run.
  final List<DiaryCarryoverDayDetail> previousDays;

  /// Whether calorie cycling has modified today's base goal.
  bool get hasCyclingAdjustment => cyclingAdjustmentKcal.round() != 0;

  /// Whether today is an active training day.
  bool get isTrainingDay => cyclingAdjustmentKcal > 0;

  /// Whether Schutzregel C capped the daily carryover reduction.
  bool get wasSafetyCapActive {
    if (totalCarryoverBeforeTodayKcal >= 0 || remainingRunDays <= 0) {
      return false;
    }
    final rawDailyKcal = totalCarryoverBeforeTodayKcal / remainingRunDays;
    return rawDailyKcal.abs() > carryoverKcal.abs() + 0.5;
  }

  /// Carbs delta in grams from the carryover (75% / 4.1).
  double get carryoverCarbsDeltaGrams {
    if (carryoverKcal == 0) return 0;
    return carryoverKcal > 0
        ? (carryoverKcal * carryoverCarbFraction) / carbEnergyDensityKcalPerGram
        : -((carryoverKcal.abs() * carryoverCarbFraction) /
              carbEnergyDensityKcalPerGram);
  }

  /// Fat delta in grams from the carryover (25% / 9.3).
  double get carryoverFatDeltaGrams {
    if (carryoverKcal == 0) return 0;
    return carryoverKcal > 0
        ? (carryoverKcal * carryoverFatFraction) / fatEnergyDensityKcalPerGram
        : -((carryoverKcal.abs() * carryoverFatFraction) /
              fatEnergyDensityKcalPerGram);
  }
}

class _DiaryDailyBudgetDetailsResolver {
  const _DiaryDailyBudgetDetailsResolver({
    required this.weekOverview,
    required this.selectedDayOverview,
    required this.metrics,
    required this.isPauseDay,
    required this.carryoverStartDate,
  });

  final CalorieWeekOverview weekOverview;
  final CalorieWeekDayOverview selectedDayOverview;
  final DiaryDailyBalanceMetrics metrics;
  final bool isPauseDay;
  final DateTime carryoverStartDate;

  DiaryDailyBudgetDetailsData resolve() {
    final previousDays = _resolvePreviousDays();
    final unadjustedBase = selectedDayOverview.baseGoalKcal;
    final dayBaseGoal = metrics.baseGoalKcal;
    final cyclingAdjustment = unadjustedBase > 0
        ? (dayBaseGoal - unadjustedBase)
        : 0.0;

    return DiaryDailyBudgetDetailsData(
      selectedDay: selectedDayOverview.date,
      unadjustedBaseGoalKcal: unadjustedBase > 0 ? unadjustedBase : null,
      cyclingAdjustmentKcal: cyclingAdjustment,
      baseGoalKcal: metrics.baseGoalKcal,
      carryoverKcal: metrics.carryoverKcal,
      targetKcal: metrics.targetKcal,
      eatenKcal: metrics.eatenKcal,
      dayLeftKcal: metrics.dayLeftKcal,
      isPauseDay: isPauseDay,
      totalCarryoverBeforeTodayKcal: _sumCarryover(previousDays),
      remainingRunDays: _resolveRemainingRunDays(),
      previousDays: List<DiaryCarryoverDayDetail>.unmodifiable(previousDays),
    );
  }

  List<DiaryCarryoverDayDetail> _resolvePreviousDays() {
    return weekOverview.days
        .where(_isFinishedDayInActiveRun)
        .map(_toCarryoverDayDetail)
        .toList(growable: false);
  }

  bool _isFinishedDayInActiveRun(CalorieWeekDayOverview day) {
    final date = normalizeDiaryDay(day.date);
    return date.isBefore(normalizeDiaryDay(selectedDayOverview.date)) &&
        !date.isBefore(normalizeDiaryDay(carryoverStartDate));
  }

  int _resolveRemainingRunDays() {
    final completedDays = normalizeDiaryDay(
      selectedDayOverview.date,
    ).difference(normalizeDiaryDay(carryoverStartDate)).inDays;
    return math.max(
      1,
      calorieGoalRunLengthDays -
          completedDays.clamp(0, calorieGoalRunLengthDays - 1),
    );
  }
}

DiaryCarryoverDayDetail _toCarryoverDayDetail(
  CalorieWeekDayOverview day,
) {
  final differenceKcal = day.goalKcal - day.countedTotalKcal;
  return DiaryCarryoverDayDetail(
    date: day.date,
    goalKcal: day.goalKcal,
    consumedKcal: day.countedTotalKcal,
    differenceKcal: differenceKcal,
    isPauseDay: day.isPauseDay,
  );
}

double _sumCarryover(Iterable<DiaryCarryoverDayDetail> days) {
  return days.fold<double>(0, (sum, day) => sum + day.differenceKcal);
}
