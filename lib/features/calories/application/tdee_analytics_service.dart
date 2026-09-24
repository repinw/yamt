import 'package:yamt/features/calories/application/daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/application/daily_learned_tdee_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/domain/tdee_anticipation_calculator.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Business service that builds TDEE analytics data, trends, and projections.
abstract final class TdeeAnalyticsService {
  /// Resolves the start and end dates for a given cycle and time range.
  static ({DateTime start, DateTime end}) resolveDateWindow({
    required TdeeAnalyticsGoalCycle cycle,
    required TdeeAnalyticsTimeRange timeRange,
    required DateTime today,
  }) {
    final normalizedToday = normalizeDiaryDay(today);
    final cycleEnd =
        cycle.endDate != null && cycle.endDate!.isBefore(normalizedToday)
        ? cycle.endDate!
        : normalizedToday;

    final cycleStart = cycle.startDate.isAfter(cycleEnd)
        ? cycleEnd
        : cycle.startDate;

    final dayCount = timeRange.dayCount;
    if (dayCount == null) {
      return (start: cycleStart, end: cycleEnd);
    }

    final rawWindowStart = cycleEnd.subtract(Duration(days: dayCount - 1));
    final windowStart =
        (!cycle.isAllGoals && rawWindowStart.isBefore(cycleStart))
        ? cycleStart
        : rawWindowStart;

    return (start: windowStart, end: cycleEnd);
  }

  /// Resolves one continuous window spanning all selected goal cycles.
  static ({DateTime start, DateTime end}) resolveDateWindowForCycles({
    required List<TdeeAnalyticsGoalCycle> cycles,
    required TdeeAnalyticsTimeRange timeRange,
    required DateTime today,
  }) {
    final normalizedToday = normalizeDiaryDay(today);
    if (cycles.isEmpty) {
      return (start: normalizedToday, end: normalizedToday);
    }
    var start = cycles.first.startDate;
    var end = cycles.first.endDate ?? normalizedToday;
    for (final cycle in cycles.skip(1)) {
      if (cycle.startDate.isBefore(start)) {
        start = cycle.startDate;
      }
      final candidateEnd = cycle.endDate ?? normalizedToday;
      if (candidateEnd.isAfter(end)) {
        end = candidateEnd;
      }
    }
    final dayCount = timeRange.dayCount;
    if (dayCount != null) {
      final rangeStart = end.subtract(Duration(days: dayCount - 1));
      if (rangeStart.isAfter(start)) {
        start = rangeStart;
      }
    }
    return (start: normalizeDiaryDay(start), end: normalizeDiaryDay(end));
  }

  /// Builds daily analytics points from loaded inputs.
  static List<TdeeAnalyticsPoint> buildPoints({
    required DateTime startDate,
    required DateTime endDate,
    required CalorieGoalSettings settings,
    required Map<String, DailyLearnedTdeeGoalData?> learnedTdeeByDay,
    required Map<String, List<CalorieEntry>> entriesByDay,
    required DailyWeightSeries weights,
  }) {
    final days = buildCalorieCarryoverDateRange(
      startInclusive: startDate,
      endExclusive: nextDiaryDay(endDate),
    );

    final points = <TdeeAnalyticsPoint>[];
    for (final day in days) {
      final key = diaryDayKey(day);
      final learnedData = learnedTdeeByDay[key];
      final entries = entriesByDay[key] ?? const <CalorieEntry>[];
      final intake = entries.isEmpty
          ? null
          : entries.fold<double>(0, (sum, e) => sum + e.totalKcal);
      final target = settings.goalKcalForDay(day);

      final fallbackBaseTdee = DailyLearnedTdeeResolver.learnedTdeeSeed(
        settings: settings,
        day: day,
        fallbackGoalKcal: target,
      );
      final baseTdee = learnedData?.calculatedBaseTdeeKcal ?? fallbackBaseTdee;
      final totalTdee = learnedData?.measured.measuredTotalTdeeKcal ?? baseTdee;

      points.add(
        TdeeAnalyticsPoint(
          day: day,
          learnedBaseTdeeKcal: baseTdee > 0 ? baseTdee : null,
          totalTdeeKcal: totalTdee > 0 ? totalTdee : null,
          targetKcal: target > 0 ? target : null,
          intakeKcal: intake,
          scaleWeightKg: weights.rawByDay[key],
          trendWeightKg: weights.trendByDay[key],
          isHolding: learnedData == null,
        ),
      );
    }
    return List<TdeeAnalyticsPoint>.unmodifiable(points);
  }

  /// Computes summary metrics across the points.
  ///
  /// Weight numbers use the trend weight, not single weigh-ins. The weekly
  /// rate uses only trend days inside the window, so it matches the chart.
  static TdeeAnalyticsSummary buildSummary({
    required List<TdeeAnalyticsPoint> points,
    required DailyWeightSeries weights,
  }) {
    if (points.isEmpty) {
      return const TdeeAnalyticsSummary(
        averageTdeeKcal: 0,
        tdeeDifferenceKcal: 0,
      );
    }

    final tdeeValues = points
        .map((p) => p.learnedBaseTdeeKcal)
        .whereType<double>()
        .toList(growable: false);

    final avgTdee = tdeeValues.isEmpty
        ? 0.0
        : tdeeValues.reduce((a, b) => a + b) / tdeeValues.length;

    final firstTdee = tdeeValues.firstOrNull ?? avgTdee;
    final lastTdee = tdeeValues.lastOrNull ?? avgTdee;
    final diffTdee = lastTdee - firstTdee;

    final delta3 = _calculateDelta(tdeeValues, 3);
    final delta7 = _calculateDelta(tdeeValues, 7);
    final delta14 = _calculateDelta(tdeeValues, 14);

    final intakeValues = points
        .map((p) => p.intakeKcal)
        .whereType<double>()
        .toList(growable: false);
    final avgIntake = intakeValues.isEmpty
        ? null
        : intakeValues.reduce((a, b) => a + b) / intakeValues.length;

    final trendPoints = points
        .where((p) => p.trendWeightKg != null)
        .toList(growable: false);
    final currentWeight = trendPoints.lastOrNull?.trendWeightKg;
    final firstWeight = trendPoints.firstOrNull?.trendWeightKg;
    // A change needs at least two days of trend weight.
    final weightChange = trendPoints.length >= 2
        ? currentWeight! - firstWeight!
        : null;
    final slope = trendPoints.isEmpty
        ? null
        : weights.slopeKgPerDay(
            endDay: trendPoints.last.day,
            notBefore: points.first.day,
          );

    return TdeeAnalyticsSummary(
      averageTdeeKcal: avgTdee,
      tdeeDifferenceKcal: diffTdee,
      threeDayDeltaKcal: delta3,
      sevenDayDeltaKcal: delta7,
      fourteenDayDeltaKcal: delta14,
      averageIntakeKcal: avgIntake,
      currentWeightKg: currentWeight,
      weightChangeKg: weightChange,
      weeklyRateKg: slope == null ? null : slope * DateTime.daysPerWeek,
    );
  }

  /// Computes anticipation projection from the recent trend weight.
  static TdeeAnticipationProjection? buildAnticipation({
    required TdeeAnalyticsGoalCycle cycle,
    required DailyWeightSeries weights,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final lastDay = weights.lastDay;
    if (!cycle.isActive || cycle.targetWeightKg == null || lastDay == null) {
      return null;
    }

    final endDay = lastDay.isAfter(windowEnd) ? windowEnd : lastDay;
    final currentWeight = weights.trendFor(endDay);
    final recentTrendPerDay = weights.slopeKgPerDay(
      endDay: endDay,
      notBefore: windowStart,
    );
    if (currentWeight == null || recentTrendPerDay == null) {
      return null;
    }

    final projection = TdeeAnticipationCalculator.calculate(
      currentWeightKg: currentWeight,
      targetWeightKg: cycle.targetWeightKg,
      goalMode: cycle.goalMode,
      recentWeightTrendKgPerDay: recentTrendPerDay,
      startDate: endDay,
      plannedSpeedKgPerWeek: cycle.goalSpeedKgPerWeek,
    );
    final plannedSpeed = cycle.goalSpeedKgPerWeek;
    if (projection?.isMovingAway != true ||
        plannedSpeed == null ||
        plannedSpeed <= 0) {
      return projection;
    }
    final plannedDailyRate = plannedSpeed / DateTime.daysPerWeek;
    return TdeeAnticipationCalculator.calculate(
      currentWeightKg: currentWeight,
      targetWeightKg: cycle.targetWeightKg,
      goalMode: cycle.goalMode,
      recentWeightTrendKgPerDay: cycle.goalMode == CalorieGoalMode.lose
          ? -plannedDailyRate
          : plannedDailyRate,
      startDate: endDay,
      plannedSpeedKgPerWeek: plannedSpeed,
    );
  }

  static double? _calculateDelta(List<double> values, int daysBack) {
    if (values.length <= daysBack) {
      return null;
    }
    final latest = values.last;
    final past = values[values.length - 1 - daysBack];
    return latest - past;
  }
}
