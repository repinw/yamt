import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';

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
const _kcalPerKilogram = 7700.0;
const _maxWeeklyGoalAdjustmentKcal = 200.0;

/// Defines calorie weekly check in calculation.
class CalorieWeeklyCheckInCalculation {
  /// The calorie weekly check in calculation.
  const new({
    required this.trendWeightChangePerDay,
    required this.averageIntakeKcal,
    required this.previousTdeeKcal,
    required this.measuredTdeeKcal,
    required this.calculatedTdeeKcal,
    required this.newGoalKcal,
    required this.dynamicGoalTodayKcal,
  });

  /// The smoothed weight trend at the window end, in kg per day.
  final double trendWeightChangePerDay;

  /// The average intake of the window days.
  final double averageIntakeKcal;

  /// The TDEE that the window's average intake and the weight trend at the
  /// window end imply.
  final double measuredTdeeKcal;

  /// The daily TDEE at the window end.
  final double calculatedTdeeKcal;

  /// The daily TDEE on the day before the window.
  final double previousTdeeKcal;

  /// The new daily goal kcal after target mode and movement cap.
  final double newGoalKcal;

  /// The dynamic goal today kcal.
  final double dynamicGoalTodayKcal;
}

/// Turns the daily TDEE into the goal of a weekly check-in.
abstract final class CalorieWeeklyCheckInCalculator {
  /// The check-in of a window from the daily TDEE [atWindowEnd].
  ///
  /// The new goal follows goal mode and pace and moves at most
  /// 200 kcal from [previousGoalKcal].
  static CalorieWeeklyCheckInCalculation fromDailyTdee({
    required DailyTdeeEstimate atWindowEnd,
    required double previousTdeeKcal,
    required double averageIntakeKcal,
    required double previousGoalKcal,
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
  }) {
    final tdeeKcal = atWindowEnd.tdeeKcal;
    final newGoalKcal = clampGoalAdjustment(
      previousGoalKcal: previousGoalKcal,
      newGoalKcal: calculateGoalFromLearnedTdee(
        learnedTdeeKcal: tdeeKcal,
        goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
            ? 0.0
            : goalSpeedKgPerWeek,
        isLosing: goalMode == CalorieGoalMode.lose,
        isGaining: goalMode == CalorieGoalMode.gain,
      ),
    );
    return CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: atWindowEnd.trendKgPerDay,
      averageIntakeKcal: averageIntakeKcal,
      previousTdeeKcal: previousTdeeKcal,
      measuredTdeeKcal:
          averageIntakeKcal - atWindowEnd.trendKgPerDay * _kcalPerKilogram,
      calculatedTdeeKcal: tdeeKcal,
      newGoalKcal: newGoalKcal,
      dynamicGoalTodayKcal: newGoalKcal.clamp(
        minimumResolvedDailyCalorieGoalKcal,
        double.infinity,
      ),
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

  /// Clamp one goal movement to at most 200 kcal.
  static double clampGoalAdjustment({
    required double previousGoalKcal,
    required double newGoalKcal,
  }) {
    return newGoalKcal.clamp(
      previousGoalKcal - _maxWeeklyGoalAdjustmentKcal,
      previousGoalKcal + _maxWeeklyGoalAdjustmentKcal,
    );
  }
}
