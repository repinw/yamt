import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/daily_tdee_series.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_tdee_offsets.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// The daily TDEE that weekly check-ins read, from the first goal through
/// the last window end, and the seed it starts from.
typedef WeeklyCheckInDailyTdee = ({
  Map<String, DailyTdeeEstimate> estimates,
  double seedKcal,
});

/// Runs the daily TDEE for the check-ins whose windows end by [endDate].
WeeklyCheckInDailyTdee weeklyCheckInDailyTdee({
  required CalorieGoalSettings settings,
  required DateTime learningStartDate,
  required DateTime endDate,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required DailyWeightSeries weights,
}) {
  return (
    estimates: DailyTdeeSeries.estimate(
      startDate: learningStartDate,
      endDate: endDate,
      // The windows are complete, so the last day counts too.
      today: nextLocalDay(endDate),
      settings: settings,
      entriesByDay: entriesByDay,
      weights: weights,
    ),
    seedKcal: DailyTdeeSeries.startTdeeKcal(settings, learningStartDate),
  );
}

/// The check-in of [window] from [dailyTdee].
///
/// The goal before the check-in is the corrected base goal of the window
/// end; [windowDays] give the average intake of the window. The daily TDEE
/// must cover the window end.
CalorieWeeklyCheckInCalculation calculateWeeklyCheckInFromDailyTdee({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn window,
  required WeeklyCheckInDailyTdee dailyTdee,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
}) {
  final atWindowEnd = dailyTdee.estimates[localDayKey(window.windowEndDate)];
  if (atWindowEnd == null) {
    throw StateError('The daily TDEE does not reach the check-in window.');
  }
  final profile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: window.windowEndDate,
  );
  return CalorieWeeklyCheckInCalculator.fromDailyTdee(
    atWindowEnd: atWindowEnd,
    previousTdeeKcal:
        dailyTdee
            .estimates[localDayKey(previousLocalDay(window.windowStartDate))]
            ?.tdeeKcal ??
        dailyTdee.seedKcal,
    averageIntakeKcal: CalorieDomainMath.average([
      for (final day in windowDays) ?day.resolvedIntakeKcal,
    ]),
    // The ±200 kcal clamp counts from the goal the user had on the last
    // day, with its daily TDEE correction.
    previousGoalKcal: settings
        .withGoalOffsets(
          goalTdeeOffsets(
            settings: settings,
            startDate: window.windowEndDate,
            today: window.windowEndDate,
            tdeeByDay: dailyTdee.estimates,
          ),
        )
        .baseGoalKcalForDay(window.windowEndDate),
    goalMode: profile?.goalMode ?? CalorieGoalMode.maintain,
    goalSpeedKgPerWeek: profile?.goalSpeedKgPerWeek ?? 0,
  );
}

/// Whether the check-in of [window] rests on thin data: the daily TDEE held
/// at the window end, or the last 28 days have two weight points or fewer.
bool isWeeklyCheckInLowConfidence({
  required PendingCalorieGoalWeeklyCheckIn window,
  required WeeklyCheckInDailyTdee dailyTdee,
  required int recentWeightPointCount,
}) {
  final isHolding =
      dailyTdee.estimates[localDayKey(window.windowEndDate)]?.isHolding ?? true;
  return isHolding || recentWeightPointCount <= 2;
}
