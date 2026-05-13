import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';

/// The minimum resolved daily calorie goal kcal.
const double minimumResolvedDailyCalorieGoalKcal =
    minimumDailyCalorieBudgetKcal;

/// The weekly check in window length days.
const weeklyCheckInWindowLengthDays = 7;

/// The weekly check in missing intake block threshold.
const weeklyCheckInMissingIntakeBlockThreshold = 3;

/// The learned tdee stale after days.
const learnedTdeeStaleAfterDays = 14;

/// The learned tdee urgent stale after days.
const learnedTdeeUrgentStaleAfterDays = 28;
const _emaHistoryWeight = 0.7;
const _emaNewDataWeight = 0.3;
const _kcalPerKilogram = 7000.0;
const _maxWeeklyGoalAdjustmentKcal = 200.0;
const _weeklyCheckInLogName = 'CalorieWeeklyCheckInCalculator';

/// Minimum completed intake days before daily learned TDEE is trusted.
const int dailyLearnedTdeeMinimumCompleteDays =
    weeklyCheckInWindowLengthDays + 1;

/// Maximum completed intake days used for daily learned TDEE.
const dailyLearnedTdeeMaximumLookbackDays = 28;

/// Defines calorie weekly check in weight point.
class CalorieWeeklyCheckInWeightPoint {
  /// The calorie weekly check in weight point.
  const CalorieWeeklyCheckInWeightPoint({
    required this.dayIndex,
    required this.weightKg,
  });

  /// The day index.
  final int dayIndex;

  /// The weight kg.
  final double weightKg;
}

/// Defines calorie weekly check in calculation.
class CalorieWeeklyCheckInCalculation {
  /// The calorie weekly check in calculation.
  const CalorieWeeklyCheckInCalculation({
    required this.trendWeightChangePerDay,
    required this.averageIntakeKcal,
    required this.measuredTrueTdeeKcal,
    required this.calculatedTrueTdeeKcal,
    required this.newGoalKcal,
    required this.lastWeekAverageActiveKcal,
    required this.todayActiveKcal,
    required this.activityDeltaKcal,
    required this.dynamicGoalTodayKcal,
  });

  /// The trend weight change per day.
  final double trendWeightChangePerDay;

  /// The average intake kcal.
  final double averageIntakeKcal;

  /// The measured true tdee kcal before smoothing.
  final double measuredTrueTdeeKcal;

  /// The smoothed learned maintenance tdee kcal.
  final double calculatedTrueTdeeKcal;

  /// The new goal kcal.
  final double newGoalKcal;

  /// The last week average active kcal.
  final double lastWeekAverageActiveKcal;

  /// The today active kcal.
  final int todayActiveKcal;

  /// The activity delta kcal.
  final double activityDeltaKcal;

  /// The dynamic goal today kcal.
  final double dynamicGoalTodayKcal;
}

/// Defines measured TDEE calculation before EMA smoothing.
class CalorieMeasuredTdeeCalculation {
  /// The measured TDEE calculation.
  const CalorieMeasuredTdeeCalculation({
    required this.trendWeightChangePerDay,
    required this.averageIntakeKcal,
    required this.measuredTrueTdeeKcal,
  });

  /// The trend weight change per day.
  final double trendWeightChangePerDay;

  /// The average intake kcal.
  final double averageIntakeKcal;

  /// The measured true tdee kcal before smoothing.
  final double measuredTrueTdeeKcal;
}

/// Defines learned TDEE target calculation from measured data.
class CalorieLearnedTdeeGoalCalculation {
  /// The learned TDEE goal calculation.
  const CalorieLearnedTdeeGoalCalculation({
    required this.measured,
    required this.calculatedTrueTdeeKcal,
    required this.rawGoalKcal,
    required this.newGoalKcal,
  });

  /// The measured TDEE calculation.
  final CalorieMeasuredTdeeCalculation measured;

  /// The smoothed learned maintenance tdee kcal.
  final double calculatedTrueTdeeKcal;

  /// The goal before movement clamping.
  final double rawGoalKcal;

  /// The final goal after movement clamping.
  final double newGoalKcal;
}

/// Defines calorie weekly check in calculator.
abstract final class CalorieWeeklyCheckInCalculator {
  /// Calculate.
  static CalorieWeeklyCheckInCalculation calculate({
    required double previousGoalKcal,
    required double previousLearnedTdeeKcal,
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required List<double> intakeKcalByDay,
    required List<int> lastWeekActiveKcalByDay,
    required int todayActiveKcal,
    required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  }) {
    assert(
      intakeKcalByDay.length >= weeklyCheckInWindowLengthDays - 1 &&
          intakeKcalByDay.length <= dailyLearnedTdeeMaximumLookbackDays,
      'Weekly check-in requires 6 to 28 intake values.',
    );
    assert(
      lastWeekActiveKcalByDay.isNotEmpty,
      'Weekly check-in activity baseline values must not be empty.',
    );
    assert(
      weightPoints.length >= 2,
      'Weekly check-in requires at least 2 weight points.',
    );

    final goalCalculation = calculateLearnedGoal(
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
          ? 0.0
          : goalSpeedKgPerWeek,
      isLosing: goalMode == CalorieGoalMode.lose,
      isGaining: goalMode == CalorieGoalMode.gain,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightPoints,
    );
    final measured = goalCalculation.measured;
    final trendWeightChangePerDay = measured.trendWeightChangePerDay;
    final averageIntakeKcal = measured.averageIntakeKcal;
    final measuredTrueTdeeKcal = measured.measuredTrueTdeeKcal;
    final calculatedTrueTdeeKcal = goalCalculation.calculatedTrueTdeeKcal;
    final rawNewGoalKcal = goalCalculation.rawGoalKcal;
    final newGoalKcal = goalCalculation.newGoalKcal;
    final lastWeekAverageActiveKcal = _averageInt(lastWeekActiveKcalByDay);
    final activityDeltaKcal = calculateLearnedActivityBonusKcal(
      todayActiveKcal: todayActiveKcal,
      averageActiveKcal: lastWeekAverageActiveKcal,
    );
    final dynamicGoalTodayKcal = (newGoalKcal + activityDeltaKcal).clamp(
      minimumResolvedDailyCalorieGoalKcal,
      double.infinity,
    );
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
          'previousLearnedTdeeKcal='
          '${previousLearnedTdeeKcal.toStringAsFixed(2)} '
          'goalMode=${goalMode.name} '
          'goalSpeedKgPerWeek=${goalSpeedKgPerWeek.toStringAsFixed(2)} '
          'intakeKcalByDay=[$intakeLabel] '
          'lastWeekActiveKcalByDay=[$activeLabel] '
          'todayActiveKcal=$todayActiveKcal '
          'weightPoints=[$weightPointsLabel] '
          '-> trendWeightChangePerDay='
          '${trendWeightChangePerDay.toStringAsFixed(5)} '
          'averageIntakeKcal=${averageIntakeKcal.toStringAsFixed(2)} '
          'measuredTrueTdeeKcal='
          '${measuredTrueTdeeKcal.toStringAsFixed(2)} '
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
      measuredTrueTdeeKcal: measuredTrueTdeeKcal,
      calculatedTrueTdeeKcal: calculatedTrueTdeeKcal,
      newGoalKcal: newGoalKcal,
      lastWeekAverageActiveKcal: lastWeekAverageActiveKcal,
      todayActiveKcal: todayActiveKcal,
      activityDeltaKcal: activityDeltaKcal,
      dynamicGoalTodayKcal: dynamicGoalTodayKcal,
    );
  }

  /// Calculate goal from learned tdee.
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

  /// Calculate measured TDEE before EMA smoothing.
  static CalorieMeasuredTdeeCalculation calculateMeasuredTdee({
    required List<double> intakeKcalByDay,
    required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  }) {
    final smoothedWeightPoints = _smoothWeightPoints(weightPoints);
    final trendWeightChangePerDay = _calculateSlope(smoothedWeightPoints);
    final averageIntakeKcal = CalorieDomainMath.average(intakeKcalByDay);
    final measuredTrueTdeeKcal =
        averageIntakeKcal - (trendWeightChangePerDay * _kcalPerKilogram);
    return CalorieMeasuredTdeeCalculation(
      trendWeightChangePerDay: trendWeightChangePerDay,
      averageIntakeKcal: averageIntakeKcal,
      measuredTrueTdeeKcal: measuredTrueTdeeKcal,
    );
  }

  /// Smooth measured TDEE into the learned TDEE estimate.
  static double smoothLearnedTdee({
    required double previousLearnedTdeeKcal,
    required double measuredTrueTdeeKcal,
  }) {
    return (previousLearnedTdeeKcal * _emaHistoryWeight) +
        (measuredTrueTdeeKcal * _emaNewDataWeight);
  }

  /// Calculate learned TDEE and target goal from measured data.
  static CalorieLearnedTdeeGoalCalculation calculateLearnedGoal({
    required double previousGoalKcal,
    required double previousLearnedTdeeKcal,
    required double goalSpeedKgPerWeek,
    required bool isLosing,
    required bool isGaining,
    required List<double> intakeKcalByDay,
    required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
    double maxGoalAdjustmentKcal = _maxWeeklyGoalAdjustmentKcal,
  }) {
    final measured = calculateMeasuredTdee(
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightPoints,
    );
    final calculatedTrueTdeeKcal = smoothLearnedTdee(
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      measuredTrueTdeeKcal: measured.measuredTrueTdeeKcal,
    );
    final rawGoalKcal = calculateGoalFromLearnedTdee(
      learnedTdeeKcal: calculatedTrueTdeeKcal,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      isLosing: isLosing,
      isGaining: isGaining,
    );
    final newGoalKcal = clampGoalAdjustment(
      previousGoalKcal: previousGoalKcal,
      newGoalKcal: rawGoalKcal,
      maxGoalAdjustmentKcal: maxGoalAdjustmentKcal,
    );
    return CalorieLearnedTdeeGoalCalculation(
      measured: measured,
      calculatedTrueTdeeKcal: calculatedTrueTdeeKcal,
      rawGoalKcal: rawGoalKcal,
      newGoalKcal: newGoalKcal,
    );
  }

  /// Clamp one goal movement to a maximum kcal delta.
  static double clampGoalAdjustment({
    required double previousGoalKcal,
    required double newGoalKcal,
    double maxGoalAdjustmentKcal = _maxWeeklyGoalAdjustmentKcal,
  }) {
    final minGoalKcal = previousGoalKcal - maxGoalAdjustmentKcal;
    final maxGoalKcal = previousGoalKcal + maxGoalAdjustmentKcal;
    return newGoalKcal.clamp(minGoalKcal, maxGoalKcal);
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

  static double _averageInt(List<int> values) {
    return values.fold<int>(0, (sum, value) => sum + value) / values.length;
  }

  static double _medianOfThree(double first, double second, double third) {
    final values = <double>[first, second, third]..sort();
    return values[1];
  }
}
