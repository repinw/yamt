import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';

/// Defines calorie weekly check in blocked reason.
enum CalorieWeeklyCheckInBlockedReason {
  /// Documented member.
  missingIntakeDays,

  /// Documented member.
  tooManyMissingIntakeDays,

  /// Documented member.
  skippedDayWithoutPriorAverage,

  /// Documented member.
  missingWindowStartWeight,

  /// Documented member.
  missingWindowEndWeight,

  /// Documented member.
  unstableWeightData,
}

/// Defines calorie learned tdee freshness.
enum CalorieLearnedTdeeFreshness {
  /// None.
  none,

  /// Fresh.
  fresh,

  /// Stale.
  stale,

  /// Urgent.
  urgent,
}

/// Defines calorie weekly check in window day.
class CalorieWeeklyCheckInWindowDay {
  /// The calorie weekly check in window day.
  const CalorieWeeklyCheckInWindowDay({
    required this.day,
    required this.hasEntries,
    required this.loggedIntakeKcal,
    required this.resolvedIntakeKcal,
    required this.isSkippedIntakeDay,
    required this.isHeartDay,
    required this.activeKcal,
    required this.weightKg,
  });

  /// The day.
  final DateTime day;

  /// Whether entries.
  final bool hasEntries;

  /// The logged intake kcal.
  final double loggedIntakeKcal;

  /// The resolved intake kcal.
  final double? resolvedIntakeKcal;

  /// Whether skipped intake day.
  final bool isSkippedIntakeDay;

  /// Whether this day is protected by a spent heart.
  final bool isHeartDay;

  /// The active kcal.
  final int activeKcal;

  /// The weight kg.
  final double? weightKg;
}

/// Defines calorie weekly check in data.
class CalorieWeeklyCheckInData {
  /// The calorie weekly check in data.
  const CalorieWeeklyCheckInData({
    required this.pendingWeeklyCheckIn,
    required this.shouldAutoOpen,
    required this.days,
    required this.calculation,
    required this.blockedReason,
    required this.missingIntakeDays,
    required this.missingWeightDays,
    required this.freshness,
    required this.latestLearnedTdeeAt,
    required this.lowConfidence,
    this.cacheWeeklyCheckIn,
    this.inputHash,
  });

  /// The pending weekly check in.
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;

  /// Weekly window whose learned TDEE cache can be refreshed.
  final PendingCalorieGoalWeeklyCheckIn? cacheWeeklyCheckIn;

  /// Whether auto open.
  final bool shouldAutoOpen;

  /// The days.
  final List<CalorieWeeklyCheckInWindowDay> days;

  /// The calculation.
  final CalorieWeeklyCheckInCalculation? calculation;

  /// The blocked reason.
  final CalorieWeeklyCheckInBlockedReason? blockedReason;

  /// The missing intake days.
  final List<DateTime> missingIntakeDays;

  /// The missing weight days.
  final List<DateTime> missingWeightDays;

  /// The freshness.
  final CalorieLearnedTdeeFreshness freshness;

  /// The latest learned tdee at.
  final DateTime? latestLearnedTdeeAt;

  /// The low confidence.
  final bool lowConfidence;

  /// Stable hash for inputs used by [calculation].
  final String? inputHash;

  /// Whether pending.
  bool get hasPending => pendingWeeklyCheckIn != null;

  /// Whether blocked.
  bool get isBlocked => blockedReason != null;

  /// Whether ready.
  bool get isReady => hasPending && !isBlocked && calculation != null;

  /// The show diary hint.
  bool get showDiaryHint {
    final pending = pendingWeeklyCheckIn;
    if (pending != null) {
      return !pending.isDismissed;
    }
    return freshness == CalorieLearnedTdeeFreshness.stale ||
        freshness == CalorieLearnedTdeeFreshness.urgent;
  }
}
