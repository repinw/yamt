import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_daily_tdee.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_input_hash.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Evaluates the check-in window of [dates] from loaded inputs.
///
/// [entriesByDay] holds the entries from the learning start to the window
/// end. The weekly check-in and the debug dump both call this, so the dump
/// shows what the check-in decides.
({
  CalorieWeeklyCheckInDayData dayData,
  CalorieWeeklyCheckInWeightData weightData,
})
evaluateWeeklyCheckInWindow({
  required CalorieGoalSettings settings,
  required CalorieWeeklyCheckInWindowDates dates,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required DailyWeightSeries weights,
}) {
  final window = dates.pendingWeeklyCheckIn;
  final weightData = mergeWeeklyCheckInWeights(
    dates: dates,
    anchorEntry: dates.anchorEntry,
    dailyWeightByDay: weights.rawByDay,
  );
  final windowIntakeData = resolveWeeklyWindowIntakeData(
    days: dates.windowDays,
    calorieEntriesByDay: entriesByDay,
    settings: settings,
    weightByDay: weightData.weightByDay,
  );
  if (windowIntakeData.blockedReason != null) {
    return (
      dayData: CalorieWeeklyCheckInDayData(
        days: windowIntakeData.days,
        calculation: null,
        blockedReason: windowIntakeData.blockedReason,
        missingIntakeDays: windowIntakeData.missingIntakeDays,
        missingWeightDays: const <DateTime>[],
        lowConfidence: false,
        inputHash: null,
      ),
      weightData: weightData,
    );
  }

  final weightBlockedData = validateWeeklyCheckInWeightData(
    dates: dates,
    weightData: weightData,
    windowDays: windowIntakeData.days,
    missingIntakeDays: windowIntakeData.missingIntakeDays,
  );
  if (weightBlockedData != null) {
    return (dayData: weightBlockedData, weightData: weightData);
  }

  final dailyTdee = weeklyCheckInDailyTdee(
    settings: settings,
    learningStartDate: dates.learningStartDate,
    endDate: window.windowEndDate,
    entriesByDay: entriesByDay,
    weights: weights,
  );
  final calculation = calculateWeeklyCheckInFromDailyTdee(
    settings: settings,
    window: window,
    dailyTdee: dailyTdee,
    windowDays: windowIntakeData.days,
  );
  return (
    dayData: CalorieWeeklyCheckInDayData(
      days: windowIntakeData.days,
      calculation: calculation,
      blockedReason: null,
      missingIntakeDays: windowIntakeData.missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: isWeeklyCheckInLowConfidence(
        window: window,
        dailyTdee: dailyTdee,
        recentWeightPointCount: recentWeeklyCheckInWeightPoints(
          dates: dates,
          weightData: weightData,
        ).length,
      ),
      inputHash: weeklyCheckInInputHash(
        weeklyCheckIn: window,
        dates: dates,
        previousGoalKcal: calculation.previousGoalKcal,
        calorieEntriesByDay: entriesByDay,
        settings: settings,
        weightData: weightData,
        calculatedTdeeKcal: calculation.calculatedTdeeKcal,
      ),
      macroWeightKg: weights.trendOnOrBefore(window.windowEndDate),
    ),
    weightData: weightData,
  );
}
