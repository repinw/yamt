import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Merges daily weights and the goal-anchor weight for a check-in.
///
/// [dailyWeightByDay] holds one measured weight per day, with manual entries
/// already preferred over Health samples.
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
      weightKg: dailyWeightByDay[diaryDayKey(day)],
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
      dayKey: diaryDayKey(anchorWeightSourceDay),
      dailyWeightByDay: dailyWeightByDay,
    );
  }

  if (dates.shouldUseLearningPreviousBoundary) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.learningStartDate,
      dayIndex: 0,
      dayKey: diaryDayKey(dates.learningPreviousBoundaryDay),
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
      dayKey: diaryDayKey(previousBoundaryDay),
      dailyWeightByDay: dailyWeightByDay,
    );
  }

  _putBoundaryWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: dates.pendingWeeklyCheckIn.windowEndDate,
    dayIndex: dates.dayIndexFor(dates.nextBoundaryDay),
    dayKey: diaryDayKey(dates.nextBoundaryDay),
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

/// Returns blocked data when check-in lacks required boundary weights.
CalorieWeeklyCheckInDayData? validateWeeklyCheckInWeightData({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInWeightData weightData,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final missingWeightDays = <DateTime>[];
  final hasLearningStartWeight =
      weightData.weightByDay[diaryDayKey(dates.learningStartDate)] != null;
  final hasWindowEndWeight =
      weightData.weightByDay[diaryDayKey(
        dates.pendingWeeklyCheckIn.windowEndDate,
      )] !=
      null;
  if (weightData.weightPoints.length < 2 && !hasLearningStartWeight) {
    missingWeightDays.add(dates.learningStartDate);
    return CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
      lowConfidence: false,
      inputHash: null,
    );
  }
  if (weightData.weightPoints.length < 2 && !hasWindowEndWeight) {
    missingWeightDays.add(dates.pendingWeeklyCheckIn.windowEndDate);
    return CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
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
  final displayDayKey = diaryDayKey(displayDay);
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
