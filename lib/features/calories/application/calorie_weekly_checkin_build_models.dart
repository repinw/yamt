// Internal split models are public only so the legacy provider can import them.
// ignore_for_file: public_member_api_docs

import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_weight_point.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

class CalorieWeeklyCheckInDayData {
  const new({
    required this.days,
    required this.calculation,
    required this.blockedReason,
    required this.missingIntakeDays,
    required this.missingWeightDays,
    required this.lowConfidence,
    required this.inputHash,
    this.macroWeightKg,
  });

  final List<CalorieWeeklyCheckInWindowDay> days;
  final CalorieWeeklyCheckInCalculation? calculation;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
  final List<DateTime> missingIntakeDays;
  final List<DateTime> missingWeightDays;
  final bool lowConfidence;
  final String? inputHash;

  /// Trend weight at the end of the window for the macro targets.
  final double? macroWeightKg;
}

class CalorieWeeklyCheckInWindowDates {
  const new({
    required this.pendingWeeklyCheckIn,
    required this.anchorEntry,
    required this.anchorWeightSourceDay,
    required this.learningStartDate,
    required this.learningDays,
    required this.windowDays,
    required this.learningPreviousBoundaryDay,
    required this.shouldUseLearningPreviousBoundary,
    required this.isFirstWindow,
    required this.previousBoundaryDay,
    required this.nextBoundaryDay,
  });

  final PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn;
  final CalorieGoalHistoryEntry? anchorEntry;
  final DateTime? anchorWeightSourceDay;
  final DateTime learningStartDate;
  final List<DateTime> learningDays;
  final List<DateTime> windowDays;
  final DateTime learningPreviousBoundaryDay;
  final bool shouldUseLearningPreviousBoundary;
  final bool isFirstWindow;
  final DateTime? previousBoundaryDay;
  final DateTime nextBoundaryDay;

  int dayIndexFor(DateTime day) {
    return localDaysBetween(learningStartDate, day);
  }
}

class CalorieWeeklyCheckInWeightData {
  const new({required this.weightByDay, required this.weightPoints});

  final Map<String, double> weightByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
}

class CalorieWeeklyWindowIntakeData {
  const new _({
    required this.days,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory ready({
    required List<CalorieWeeklyCheckInWindowDay> days,
    required List<DateTime> missingIntakeDays,
  }) {
    return CalorieWeeklyWindowIntakeData._(
      days: List<CalorieWeeklyCheckInWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory blocked({
    required List<CalorieWeeklyCheckInWindowDay> days,
    required CalorieWeeklyCheckInBlockedReason blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return CalorieWeeklyWindowIntakeData._(
      days: List<CalorieWeeklyCheckInWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<CalorieWeeklyCheckInWindowDay> days;
  final List<DateTime> missingIntakeDays;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
}
