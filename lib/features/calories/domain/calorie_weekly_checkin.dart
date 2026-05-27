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
    required this.todayActiveKcal,
    required this.activityDeltaKcal,
    required this.dynamicGoalTodayKcal,
    double? measuredTotalTdeeKcal,
    double? measuredBaseTdeeKcal,
    double? calculatedBaseTdeeKcal,
    double? newBaseGoalKcal,
    double? averageCreditedActivityKcal,
    double? measuredTrueTdeeKcal,
    double? calculatedTrueTdeeKcal,
    double? newGoalKcal,
    double? lastWeekAverageActiveKcal,
  }) : measuredTotalTdeeKcal =
           measuredTotalTdeeKcal ?? measuredTrueTdeeKcal ?? 0,
       measuredBaseTdeeKcal =
           measuredBaseTdeeKcal ??
           measuredTotalTdeeKcal ??
           measuredTrueTdeeKcal ??
           0,
       calculatedBaseTdeeKcal =
           calculatedBaseTdeeKcal ?? calculatedTrueTdeeKcal ?? 0,
       newBaseGoalKcal = newBaseGoalKcal ?? newGoalKcal ?? 0,
       averageCreditedActivityKcal =
           averageCreditedActivityKcal ?? lastWeekAverageActiveKcal ?? 0;

  /// The trend weight change per day.
  final double trendWeightChangePerDay;

  /// The average intake kcal.
  final double averageIntakeKcal;

  /// The measured total TDEE kcal before activity is removed.
  final double measuredTotalTdeeKcal;

  /// The measured Base-TDEE kcal before smoothing.
  final double measuredBaseTdeeKcal;

  /// The smoothed learned Base-TDEE kcal.
  final double calculatedBaseTdeeKcal;

  /// The new base goal kcal after target mode and movement cap.
  final double newBaseGoalKcal;

  /// Average corrected activity kcal in the learning window.
  final double averageCreditedActivityKcal;

  /// The today active kcal.
  final int todayActiveKcal;

  /// The activity delta kcal.
  final double activityDeltaKcal;

  /// The dynamic goal today kcal.
  final double dynamicGoalTodayKcal;

  /// Backwards-compatible label for measured total TDEE.
  double get measuredTrueTdeeKcal => measuredTotalTdeeKcal;

  /// Backwards-compatible label for Base-TDEE while UI copy is updated.
  double get calculatedTrueTdeeKcal => calculatedBaseTdeeKcal;

  /// Backwards-compatible label for base goal.
  double get newGoalKcal => newBaseGoalKcal;

  /// Backwards-compatible label for average credited activity.
  double get lastWeekAverageActiveKcal => averageCreditedActivityKcal;
}

/// Defines measured TDEE calculation before EMA smoothing.
class CalorieMeasuredTdeeCalculation {
  /// The measured TDEE calculation.
  const CalorieMeasuredTdeeCalculation({
    required this.trendWeightChangePerDay,
    required this.averageIntakeKcal,
    double? measuredTotalTdeeKcal,
    double? measuredBaseTdeeKcal,
    double? measuredTrueTdeeKcal,
    double? averageCreditedActivityKcal,
  }) : measuredTotalTdeeKcal =
           measuredTotalTdeeKcal ?? measuredTrueTdeeKcal ?? 0,
       measuredBaseTdeeKcal =
           measuredBaseTdeeKcal ??
           measuredTotalTdeeKcal ??
           measuredTrueTdeeKcal ??
           0,
       averageCreditedActivityKcal = averageCreditedActivityKcal ?? 0;

  /// The trend weight change per day.
  final double trendWeightChangePerDay;

  /// The average intake kcal.
  final double averageIntakeKcal;

  /// The measured total TDEE kcal before activity is removed.
  final double measuredTotalTdeeKcal;

  /// The measured Base-TDEE kcal after credited activity is removed.
  final double measuredBaseTdeeKcal;

  /// Average corrected activity kcal in the learning window.
  final double averageCreditedActivityKcal;

  /// Backwards-compatible label for measured total TDEE.
  double get measuredTrueTdeeKcal => measuredTotalTdeeKcal;
}

/// Defines learned TDEE target calculation from measured data.
class CalorieLearnedTdeeGoalCalculation {
  /// The learned TDEE goal calculation.
  const CalorieLearnedTdeeGoalCalculation({
    required this.measured,
    required this.calculatedBaseTdeeKcal,
    required this.rawGoalKcal,
    required this.newBaseGoalKcal,
  });

  /// The measured TDEE calculation.
  final CalorieMeasuredTdeeCalculation measured;

  /// The smoothed learned Base-TDEE kcal.
  final double calculatedBaseTdeeKcal;

  /// The goal before movement clamping.
  final double rawGoalKcal;

  /// The final base goal after movement clamping.
  final double newBaseGoalKcal;

  /// Backwards-compatible label for Base-TDEE.
  double get calculatedTrueTdeeKcal => calculatedBaseTdeeKcal;

  /// Backwards-compatible label for base goal.
  double get newGoalKcal => newBaseGoalKcal;
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
    List<int>? learningActiveKcalByDay,
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
      rawActivityKcalByDay: learningActiveKcalByDay ?? lastWeekActiveKcalByDay,
      weightPoints: weightPoints,
    );
    final measured = goalCalculation.measured;
    final trendWeightChangePerDay = measured.trendWeightChangePerDay;
    final averageIntakeKcal = measured.averageIntakeKcal;
    final measuredTotalTdeeKcal = measured.measuredTotalTdeeKcal;
    final measuredBaseTdeeKcal = measured.measuredBaseTdeeKcal;
    final calculatedBaseTdeeKcal = goalCalculation.calculatedBaseTdeeKcal;
    final rawNewGoalKcal = goalCalculation.rawGoalKcal;
    final newBaseGoalKcal = goalCalculation.newBaseGoalKcal;
    final averageCreditedActivityKcal = measured.averageCreditedActivityKcal;
    final activityDeltaKcal = calculateActivityCreditKcal(
      rawActivityKcal: todayActiveKcal,
    );
    final dynamicGoalTodayKcal = (newBaseGoalKcal + activityDeltaKcal).clamp(
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
          'measuredTotalTdeeKcal='
          '${measuredTotalTdeeKcal.toStringAsFixed(2)} '
          'measuredBaseTdeeKcal='
          '${measuredBaseTdeeKcal.toStringAsFixed(2)} '
          'calculatedBaseTdeeKcal='
          '${calculatedBaseTdeeKcal.toStringAsFixed(2)} '
          'rawNewGoalKcal=${rawNewGoalKcal.toStringAsFixed(2)} '
          'newBaseGoalKcal=${newBaseGoalKcal.toStringAsFixed(2)} '
          'averageCreditedActivityKcal='
          '${averageCreditedActivityKcal.toStringAsFixed(2)} '
          'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
          'dynamicGoalTodayKcal=${dynamicGoalTodayKcal.toStringAsFixed(2)}';
      log(message, name: _weeklyCheckInLogName);
    }

    return CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: trendWeightChangePerDay,
      averageIntakeKcal: averageIntakeKcal,
      measuredTotalTdeeKcal: measuredTotalTdeeKcal,
      measuredBaseTdeeKcal: measuredBaseTdeeKcal,
      calculatedBaseTdeeKcal: calculatedBaseTdeeKcal,
      newBaseGoalKcal: newBaseGoalKcal,
      averageCreditedActivityKcal: averageCreditedActivityKcal,
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
    List<int> rawActivityKcalByDay = const <int>[],
  }) {
    final smoothedWeightPoints = _smoothWeightPoints(weightPoints);
    final trendWeightChangePerDay = _calculateSlope(smoothedWeightPoints);
    final averageIntakeKcal = CalorieDomainMath.average(intakeKcalByDay);
    final measuredTotalTdeeKcal =
        averageIntakeKcal - (trendWeightChangePerDay * _kcalPerKilogram);
    final measuredBaseTdeeKcal = calculateMeasuredBaseTdeeKcal(
      measuredTotalTdeeKcal: measuredTotalTdeeKcal,
      rawActivityKcalByDay: rawActivityKcalByDay,
    );
    final averageCreditedActivityKcal = calculateAverageActivityCreditKcal(
      rawActivityKcalByDay: rawActivityKcalByDay,
    );
    return CalorieMeasuredTdeeCalculation(
      trendWeightChangePerDay: trendWeightChangePerDay,
      averageIntakeKcal: averageIntakeKcal,
      measuredTotalTdeeKcal: measuredTotalTdeeKcal,
      measuredBaseTdeeKcal: measuredBaseTdeeKcal,
      averageCreditedActivityKcal: averageCreditedActivityKcal,
    );
  }

  /// Smooth measured Base-TDEE into the learned Base-TDEE estimate.
  static double smoothLearnedTdee({
    required double previousLearnedTdeeKcal,
    required double measuredBaseTdeeKcal,
  }) {
    return (previousLearnedTdeeKcal * _emaHistoryWeight) +
        (measuredBaseTdeeKcal * _emaNewDataWeight);
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
    List<int> rawActivityKcalByDay = const <int>[],
    double maxGoalAdjustmentKcal = _maxWeeklyGoalAdjustmentKcal,
  }) {
    final measured = calculateMeasuredTdee(
      intakeKcalByDay: intakeKcalByDay,
      rawActivityKcalByDay: rawActivityKcalByDay,
      weightPoints: weightPoints,
    );
    final calculatedBaseTdeeKcal = smoothLearnedTdee(
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      measuredBaseTdeeKcal: measured.measuredBaseTdeeKcal,
    );
    final rawGoalKcal = calculateGoalFromLearnedTdee(
      learnedTdeeKcal: calculatedBaseTdeeKcal,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      isLosing: isLosing,
      isGaining: isGaining,
    );
    final newBaseGoalKcal = clampGoalAdjustment(
      previousGoalKcal: previousGoalKcal,
      newGoalKcal: rawGoalKcal,
      maxGoalAdjustmentKcal: maxGoalAdjustmentKcal,
    );
    return CalorieLearnedTdeeGoalCalculation(
      measured: measured,
      calculatedBaseTdeeKcal: calculatedBaseTdeeKcal,
      rawGoalKcal: rawGoalKcal,
      newBaseGoalKcal: newBaseGoalKcal,
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

  static double _medianOfThree(double first, double second, double third) {
    final values = <double>[first, second, third]..sort();
    return values[1];
  }
}
