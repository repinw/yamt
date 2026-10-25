import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_weight_point.dart';

/// Merges daily weights and the goal-anchor weight for a check-in.
///
/// [dailyWeightByDay] holds one measured weight per day, the median of the
/// day's manual and Health weighings; ignored Health weighings do not count.
CalorieWeeklyCheckInWeightData mergeWeeklyCheckInWeights({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieGoalHistoryEntry? anchorEntry,
  required Map<String, double> dailyWeightByDay,
}) {
  final weightByDay = <String, double>{};
  final weightPointByDay = <String, CalorieWeeklyCheckInWeightPoint>{};
  for (final day in dates.learningDays) {
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: day,
      weightKg: dailyWeightByDay[localDayKey(day)],
      dayIndex: dates.dayIndexFor(day),
    );
  }

  final anchorWeightSourceDay = dates.anchorWeightSourceDay;
  if (anchorWeightSourceDay != null) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
      dayKey: localDayKey(anchorWeightSourceDay),
      dailyWeightByDay: dailyWeightByDay,
    );
  }

  if (dates.shouldUseLearningPreviousBoundary) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.learningStartDate,
      dayIndex: 0,
      dayKey: localDayKey(dates.learningPreviousBoundaryDay),
      dailyWeightByDay: dailyWeightByDay,
    );
  }

  if (dates.isFirstWindow && anchorEntry != null) {
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      weightKg: anchorEntry.calculatorProfile?.weightKg,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
    );
  }

  final previousBoundaryDay = dates.previousBoundaryDay;
  if (previousBoundaryDay != null) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
      dayKey: localDayKey(previousBoundaryDay),
      dailyWeightByDay: dailyWeightByDay,
    );
  }

  _putBoundaryWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: dates.pendingWeeklyCheckIn.windowEndDate,
    dayIndex: dates.dayIndexFor(dates.nextBoundaryDay),
    dayKey: localDayKey(dates.nextBoundaryDay),
    dailyWeightByDay: dailyWeightByDay,
    decoupleWeightPointKey: true,
  );

  final weightPoints = weightPointByDay.values.toList(growable: false)
    ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
  return CalorieWeeklyCheckInWeightData(
    weightByDay: Map<String, double>.unmodifiable(weightByDay),
    weightPoints: List<CalorieWeeklyCheckInWeightPoint>.unmodifiable(
      weightPoints,
    ),
  );
}

/// Days up to the window end whose weigh-ins count for blocking and low
/// confidence; the daily TDEE itself reads every day since the first goal.
const weeklyCheckInWeightLookbackDays = 28;

/// First day whose weigh-ins count for the check-in of [dates].
DateTime weeklyCheckInWeightLookbackStart(
  CalorieWeeklyCheckInWindowDates dates,
) {
  final lookbackStart = addLocalDays(
    dates.pendingWeeklyCheckIn.windowEndDate,
    1 - weeklyCheckInWeightLookbackDays,
  );
  return lookbackStart.isAfter(dates.learningStartDate)
      ? lookbackStart
      : dates.learningStartDate;
}

/// The weight points of [weightData] from the lookback start on.
List<CalorieWeeklyCheckInWeightPoint> recentWeeklyCheckInWeightPoints({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInWeightData weightData,
}) {
  final firstIndex = dates.dayIndexFor(weeklyCheckInWeightLookbackStart(dates));
  return [
    for (final point in weightData.weightPoints)
      if (point.dayIndex >= firstIndex) point,
  ];
}

/// Blocks the check-in when the lookback has fewer than two weight points
/// and lacks a weight at its start or at the window end.
CalorieWeeklyCheckInDayData? validateWeeklyCheckInWeightData({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInWeightData weightData,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final lookbackStart = weeklyCheckInWeightLookbackStart(dates);
  final hasEnoughPoints =
      recentWeeklyCheckInWeightPoints(
        dates: dates,
        weightData: weightData,
      ).length >=
      2;
  final hasLookbackStartWeight =
      weightData.weightByDay[localDayKey(lookbackStart)] != null;
  final hasWindowEndWeight =
      weightData.weightByDay[localDayKey(
        dates.pendingWeeklyCheckIn.windowEndDate,
      )] !=
      null;
  if (!hasEnoughPoints && !hasLookbackStartWeight) {
    return CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: [lookbackStart],
      lowConfidence: false,
      inputHash: null,
    );
  }
  if (!hasEnoughPoints && !hasWindowEndWeight) {
    return CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: [dates.pendingWeeklyCheckIn.windowEndDate],
      lowConfidence: false,
      inputHash: null,
    );
  }
  return null;
}

void _putBoundaryWeightIfAbsent({
  required Map<String, double> weightByDay,
  required Map<String, CalorieWeeklyCheckInWeightPoint> weightPointByDay,
  required DateTime displayDay,
  required int dayIndex,
  required String dayKey,
  required Map<String, double> dailyWeightByDay,
  bool decoupleWeightPointKey = false,
}) {
  _putWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: displayDay,
    weightKg: dailyWeightByDay[dayKey],
    dayIndex: dayIndex,
    weightPointKey: decoupleWeightPointKey ? dayKey : null,
  );
}

void _putWeightIfAbsent({
  required Map<String, double> weightByDay,
  required Map<String, CalorieWeeklyCheckInWeightPoint> weightPointByDay,
  required DateTime displayDay,
  required double? weightKg,
  required int dayIndex,
  String? weightPointKey,
}) {
  if (weightKg == null) {
    return;
  }
  final displayDayKey = localDayKey(displayDay);
  final ptKey = weightPointKey ?? displayDayKey;
  if (!weightByDay.containsKey(displayDayKey)) {
    weightByDay[displayDayKey] = weightKg;
  }
  if (!weightPointByDay.containsKey(ptKey)) {
    weightPointByDay[ptKey] = CalorieWeeklyCheckInWeightPoint(
      dayIndex: dayIndex,
      weightKg: weightKg,
    );
  }
}
