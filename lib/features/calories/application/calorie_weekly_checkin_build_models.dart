// Internal split models are public only so the legacy provider can import them.
// ignore_for_file: public_member_api_docs

import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

class CalorieWeeklyCheckInDayData {
  const CalorieWeeklyCheckInDayData({
    required this.days,
    required this.calculation,
    required this.blockedReason,
    required this.missingIntakeDays,
    required this.missingWeightDays,
    required this.lowConfidence,
    required this.usesHealthActivity,
    required this.inputHash,
  });

  final List<CalorieWeeklyCheckInWindowDay> days;
  final CalorieWeeklyCheckInCalculation? calculation;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
  final List<DateTime> missingIntakeDays;
  final List<DateTime> missingWeightDays;
  final bool lowConfidence;
  final bool usesHealthActivity;
  final String? inputHash;
}

class CalorieWeeklyCheckInWindowDates {
  const CalorieWeeklyCheckInWindowDates({
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

  List<DateTime> get healthWeightStartCandidates {
    return <DateTime>[
      learningStartDate,
      ?anchorWeightSourceDay,
      if (shouldUseLearningPreviousBoundary) learningPreviousBoundaryDay,
      ?previousBoundaryDay,
    ];
  }

  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}

class CalorieWeeklyCheckInHealthData {
  const CalorieWeeklyCheckInHealthData({
    required this.activeKcalByDay,
    required this.todayActiveKcal,
    required this.representativeWeightByDay,
    required this.usesHealthActivity,
  });

  final Map<String, int> activeKcalByDay;
  final int todayActiveKcal;
  final Map<String, double> representativeWeightByDay;
  final bool usesHealthActivity;
}

class CalorieWeeklyLearningSeed {
  const CalorieWeeklyLearningSeed({
    required this.previousGoalKcal,
    required this.previousLearnedTdeeKcal,
  });

  final double previousGoalKcal;
  final double previousLearnedTdeeKcal;
}

class CalorieWeeklyCheckInWeightData {
  const CalorieWeeklyCheckInWeightData({
    required this.weightByDay,
    required this.weightPoints,
  });

  final Map<String, double> weightByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
}

class CalorieWeeklyWindowIntakeData {
  const CalorieWeeklyWindowIntakeData._({
    required this.days,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory CalorieWeeklyWindowIntakeData.ready({
    required List<CalorieWeeklyCheckInWindowDay> days,
    required List<DateTime> missingIntakeDays,
  }) {
    return CalorieWeeklyWindowIntakeData._(
      days: List<CalorieWeeklyCheckInWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory CalorieWeeklyWindowIntakeData.blocked({
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

class CalorieWeeklyLearningIntakeData {
  const CalorieWeeklyLearningIntakeData._({
    required this.intakeKcalByDay,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory CalorieWeeklyLearningIntakeData.ready({
    required List<double> intakeKcalByDay,
    required List<DateTime> missingIntakeDays,
  }) {
    return CalorieWeeklyLearningIntakeData._(
      intakeKcalByDay: List<double>.unmodifiable(intakeKcalByDay),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory CalorieWeeklyLearningIntakeData.blocked({
    required CalorieWeeklyCheckInBlockedReason blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return CalorieWeeklyLearningIntakeData._(
      intakeKcalByDay: const <double>[],
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<double> intakeKcalByDay;
  final List<DateTime> missingIntakeDays;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
}
