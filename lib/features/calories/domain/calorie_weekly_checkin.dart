import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

const minimumResolvedDailyCalorieGoalKcal = 1500.0;
const weeklyCheckInWindowLengthDays = 7;
const weeklyCheckInMissingIntakeBlockThreshold = 3;
const learnedTdeeStaleAfterDays = 14;
const learnedTdeeUrgentStaleAfterDays = 28;
const _emaHistoryWeight = 0.7;
const _emaNewDataWeight = 0.3;
const _kcalPerKilogram = 7000.0;
const _maxWeeklyGoalAdjustmentKcal = 200.0;
const _weeklyCheckInLogName = 'CalorieWeeklyCheckInCalculator';

class CalorieWeeklyCheckInWeightPoint {
  const CalorieWeeklyCheckInWeightPoint({
    required this.dayIndex,
    required this.weightKg,
  });

  final int dayIndex;
  final double weightKg;
}

class CalorieWeeklyCheckInCalculation {
  const CalorieWeeklyCheckInCalculation({
    required this.trendWeightChangePerDay,
    required this.averageIntakeKcal,
    required this.calculatedTrueTdeeKcal,
    required this.newGoalKcal,
    required this.lastWeekAverageActiveKcal,
    required this.todayActiveKcal,
    required this.activityDeltaKcal,
    required this.dynamicGoalTodayKcal,
  });

  final double trendWeightChangePerDay;
  final double averageIntakeKcal;
  final double calculatedTrueTdeeKcal;
  final double newGoalKcal;
  final double lastWeekAverageActiveKcal;
  final int todayActiveKcal;
  final double activityDeltaKcal;
  final double dynamicGoalTodayKcal;
}

abstract final class CalorieWeeklyCheckInCalculator {
  static CalorieWeeklyCheckInCalculation calculate({
    required double previousGoalKcal,
    required List<double> intakeKcalByDay,
    required List<int> lastWeekActiveKcalByDay,
    required int todayActiveKcal,
    required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  }) {
    assert(intakeKcalByDay.length == weeklyCheckInWindowLengthDays);
    assert(lastWeekActiveKcalByDay.length == weeklyCheckInWindowLengthDays);
    assert(weightPoints.length >= 2);

    final smoothedWeightPoints = _smoothWeightPoints(weightPoints);
    final trendWeightChangePerDay = _calculateSlope(smoothedWeightPoints);
    final averageIntakeKcal = _averageDouble(intakeKcalByDay);
    final calculatedTrueTdeeKcal =
        averageIntakeKcal - (trendWeightChangePerDay * _kcalPerKilogram);
    final rawNewGoalKcal =
        (previousGoalKcal * _emaHistoryWeight) +
        (calculatedTrueTdeeKcal * _emaNewDataWeight);
    final newGoalKcal = _clampGoalAdjustment(
      previousGoalKcal: previousGoalKcal,
      newGoalKcal: rawNewGoalKcal,
    );
    final lastWeekAverageActiveKcal = _averageInt(lastWeekActiveKcalByDay);
    final activityDeltaKcal = todayActiveKcal - lastWeekAverageActiveKcal;
    final dynamicGoalTodayKcal = (newGoalKcal + activityDeltaKcal)
        .clamp(minimumResolvedDailyCalorieGoalKcal, double.infinity)
        .toDouble();
    if (!kReleaseMode) {
      final weightPointsLabel = weightPoints
          .map((point) {
            return '${point.dayIndex}:${point.weightKg.toStringAsFixed(2)}';
          })
          .join(',');
      final intakeLabel = intakeKcalByDay
          .map((value) => value.toStringAsFixed(2))
          .join(',');
      final activeLabel = lastWeekActiveKcalByDay.join(',');
      final message =
          'WEEKLY_TDEE_DEBUG '
          'previousGoalKcal=${previousGoalKcal.toStringAsFixed(2)} '
          'intakeKcalByDay=[$intakeLabel] '
          'lastWeekActiveKcalByDay=[$activeLabel] '
          'todayActiveKcal=$todayActiveKcal '
          'weightPoints=[$weightPointsLabel] '
          '-> trendWeightChangePerDay='
          '${trendWeightChangePerDay.toStringAsFixed(5)} '
          'averageIntakeKcal=${averageIntakeKcal.toStringAsFixed(2)} '
          'calculatedTrueTdeeKcal='
          '${calculatedTrueTdeeKcal.toStringAsFixed(2)} '
          'rawNewGoalKcal=${rawNewGoalKcal.toStringAsFixed(2)} '
          'newGoalKcal=${newGoalKcal.toStringAsFixed(2)} '
          'lastWeekAverageActiveKcal='
          '${lastWeekAverageActiveKcal.toStringAsFixed(2)} '
          'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
          'dynamicGoalTodayKcal=${dynamicGoalTodayKcal.toStringAsFixed(2)}';
      log(message, name: _weeklyCheckInLogName);
    }

    return CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: trendWeightChangePerDay,
      averageIntakeKcal: averageIntakeKcal,
      calculatedTrueTdeeKcal: calculatedTrueTdeeKcal,
      newGoalKcal: newGoalKcal,
      lastWeekAverageActiveKcal: lastWeekAverageActiveKcal,
      todayActiveKcal: todayActiveKcal,
      activityDeltaKcal: activityDeltaKcal,
      dynamicGoalTodayKcal: dynamicGoalTodayKcal,
    );
  }

  static double calculateGoalFromLearnedTdee({
    required double learnedTdeeKcal,
    required double goalSpeedKgPerWeek,
    required bool isLosing,
    required bool isGaining,
  }) {
    final dailyAdjustmentKcal =
        (goalSpeedKgPerWeek * _kcalPerKilogram) / weeklyCheckInWindowLengthDays;
    if (isLosing) {
      return learnedTdeeKcal - dailyAdjustmentKcal;
    }
    if (isGaining) {
      return learnedTdeeKcal + dailyAdjustmentKcal;
    }
    return learnedTdeeKcal;
  }

  static double _clampGoalAdjustment({
    required double previousGoalKcal,
    required double newGoalKcal,
  }) {
    final minGoalKcal = previousGoalKcal - _maxWeeklyGoalAdjustmentKcal;
    final maxGoalKcal = previousGoalKcal + _maxWeeklyGoalAdjustmentKcal;
    return newGoalKcal.clamp(minGoalKcal, maxGoalKcal).toDouble();
  }

  static List<CalorieWeeklyCheckInWeightPoint> _smoothWeightPoints(
    List<CalorieWeeklyCheckInWeightPoint> points,
  ) {
    if (points.length <= 2) {
      return points;
    }

    return <CalorieWeeklyCheckInWeightPoint>[
      points.first,
      for (var index = 1; index < points.length - 1; index += 1)
        CalorieWeeklyCheckInWeightPoint(
          dayIndex: points[index].dayIndex,
          // Use local median so one noisy weigh-in has less leverage.
          weightKg: _medianOfThree(
            points[index - 1].weightKg,
            points[index].weightKg,
            points[index + 1].weightKg,
          ),
        ),
      points.last,
    ];
  }

  static double _calculateSlope(List<CalorieWeeklyCheckInWeightPoint> points) {
    final count = points.length;
    final sumX = points.fold<double>(0, (sum, point) => sum + point.dayIndex);
    final sumY = points.fold<double>(0, (sum, point) => sum + point.weightKg);
    final sumXY = points.fold<double>(
      0,
      (sum, point) => sum + (point.dayIndex * point.weightKg),
    );
    final sumX2 = points.fold<double>(
      0,
      (sum, point) => sum + (point.dayIndex * point.dayIndex),
    );
    final numerator = (count * sumXY) - (sumX * sumY);
    final denominator = (count * sumX2) - (sumX * sumX);
    if (denominator == 0) {
      return 0;
    }
    return numerator / denominator;
  }

  static double _averageDouble(List<double> values) {
    return values.fold<double>(0, (sum, value) => sum + value) / values.length;
  }

  static double _averageInt(List<int> values) {
    return values.fold<int>(0, (sum, value) => sum + value) / values.length;
  }

  static double _medianOfThree(double first, double second, double third) {
    final values = <double>[first, second, third]..sort();
    return values[1];
  }
}
