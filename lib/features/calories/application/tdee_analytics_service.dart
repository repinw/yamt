import 'package:yamt/features/calories/application/daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/application/daily_learned_tdee_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/domain/tdee_anticipation_calculator.dart';

/// Business service that builds TDEE analytics data, trends, and projections.
abstract final class TdeeAnalyticsService {
  /// Resolves the start and end dates for a given cycle and time range.
  static ({DateTime start, DateTime end}) resolveDateWindow({
    required TdeeAnalyticsGoalCycle cycle,
    required TdeeAnalyticsTimeRange timeRange,
    required DateTime today,
  }) {
    final normalizedToday = normalizeDiaryDay(today);
    final cycleEnd = cycle.endDate != null &&
            cycle.endDate!.isBefore(normalizedToday)
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

  /// Builds daily analytics points from loaded inputs.
  static List<TdeeAnalyticsPoint> buildPoints({
    required DateTime startDate,
    required DateTime endDate,
    required CalorieGoalSettings settings,
    required Map<String, DailyLearnedTdeeGoalData?> learnedTdeeByDay,
    required Map<String, List<CalorieEntry>> entriesByDay,
    required Map<String, double> weightsByDay,
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
      final totalTdee = learnedData?.measured.measuredTotalTdeeKcal ??
          (baseTdee + (learnedData?.averageCreditedActivityKcal ?? 0));

      final weight = weightsByDay[key];
      points.add(
        TdeeAnalyticsPoint(
          day: day,
          learnedBaseTdeeKcal: baseTdee > 0 ? baseTdee : null,
          totalTdeeKcal: totalTdee > 0 ? totalTdee : null,
          targetKcal: target > 0 ? target : null,
          intakeKcal: intake,
          scaleWeightKg: weight,
          trendWeightKg: weight,
          isHolding: learnedData == null,
        ),
      );
    }
    return List<TdeeAnalyticsPoint>.unmodifiable(points);
  }

  /// Computes summary metrics across the points.
  static TdeeAnalyticsSummary buildSummary(List<TdeeAnalyticsPoint> points) {
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

    final weights = points
        .map((p) => p.scaleWeightKg)
        .whereType<double>()
        .toList(growable: false);
    final currentWeight = weights.lastOrNull;
    final firstWeight = weights.firstOrNull;
    final weightChange = (currentWeight != null && firstWeight != null)
        ? currentWeight - firstWeight
        : null;

    return TdeeAnalyticsSummary(
      averageTdeeKcal: avgTdee,
      tdeeDifferenceKcal: diffTdee,
      threeDayDeltaKcal: delta3,
      sevenDayDeltaKcal: delta7,
      fourteenDayDeltaKcal: delta14,
      averageIntakeKcal: avgIntake,
      currentWeightKg: currentWeight,
      weightChangeKg: weightChange,
    );
  }

  /// Computes anticipation projection using recent trend.
  static TdeeAnticipationProjection? buildAnticipation({
    required TdeeAnalyticsGoalCycle cycle,
    required List<TdeeAnalyticsPoint> points,
    required DateTime today,
  }) {
    if (cycle.isAllGoals || cycle.targetWeightKg == null) {
      return null;
    }

    final weightsWithDays = points
        .where((p) => p.scaleWeightKg != null)
        .map((p) => (day: p.day, weight: p.scaleWeightKg!))
        .toList(growable: false);

    if (weightsWithDays.length < 2) {
      return null;
    }

    final latest = weightsWithDays.last;
    final earliest = weightsWithDays.first;
    final daySpan = latest.day.difference(earliest.day).inDays;
    if (daySpan < 1) {
      return null;
    }

    final recentTrendPerDay = (latest.weight - earliest.weight) / daySpan;

    return TdeeAnticipationCalculator.calculate(
      currentWeightKg: latest.weight,
      targetWeightKg: cycle.targetWeightKg,
      goalMode: cycle.goalMode,
      recentWeightTrendKgPerDay: recentTrendPerDay,
      startDate: latest.day,
      plannedSpeedKgPerWeek: cycle.goalSpeedKgPerWeek,
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
