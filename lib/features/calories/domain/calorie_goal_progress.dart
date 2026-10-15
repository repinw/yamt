import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Weight of one day since the goal start.
typedef CalorieGoalProgressWeight = ({
  DateTime day,
  double? scaleWeightKg,
  double? trendWeightKg,
});

/// Learned TDEE at the end of one 7-day run.
typedef CalorieGoalProgressTdee = ({DateTime runEndDate, double tdeeKcal});

/// Weight and learned TDEE of the active goal from its start.
@immutable
class CalorieGoalProgress {
  /// Creates the progress of the active goal.
  const new({
    required this.startDate,
    required this.startWeightKg,
    required this.targetWeightKg,
    required this.weights,
    required this.tdeePoints,
  });

  /// First day of the active goal.
  final DateTime startDate;

  /// Weight when the goal started, if known.
  final double? startWeightKg;

  /// Goal weight, if the goal has one.
  final double? targetWeightKg;

  /// One entry per day from [startDate], first to last.
  final List<CalorieGoalProgressWeight> weights;

  /// Learned TDEE of every finished run, first to last.
  final List<CalorieGoalProgressTdee> tdeePoints;

  /// The weight of [day]: its trend weight, else its weigh-in, if any.
  double? weightKgOn(DateTime day) {
    for (final weight in weights) {
      if (weight.day == day) {
        return weight.trendWeightKg ?? weight.scaleWeightKg;
      }
    }
    return null;
  }

  /// Latest trend weight, if any.
  double? get latestTrendWeightKg {
    for (final weight in weights.reversed) {
      if (weight.trendWeightKg != null) {
        return weight.trendWeightKg;
      }
    }
    return null;
  }
}

/// The daily TDEE at the end of every weekly check-in run that ended
/// between [startDate] and [endDate], one per run, first to last.
///
/// [dailyTdeeKcalByDay] holds the daily TDEE by diary day key; a run end
/// without one keeps the TDEE its check-in saved. Rejected check-ins count
/// too: they measured the TDEE even though the user kept the previous goal.
List<CalorieGoalProgressTdee> calorieGoalTdeePoints({
  required CalorieGoalSettings settings,
  required Map<String, double> dailyTdeeKcalByDay,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final start = normalizeDiaryDay(startDate);
  final end = normalizeDiaryDay(endDate);
  final byRunEnd = <DateTime, double>{};
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    final runEnd = normalizeDiaryDay(snapshot.windowEndDate);
    if (runEnd.isBefore(start) || runEnd.isAfter(end)) {
      continue;
    }
    byRunEnd[runEnd] =
        dailyTdeeKcalByDay[diaryDayKey(runEnd)] ?? snapshot.calculatedTdeeKcal;
  }
  final runEnds = byRunEnd.keys.toList()..sort();
  return [
    for (final runEnd in runEnds)
      (runEndDate: runEnd, tdeeKcal: byRunEnd[runEnd]!),
  ];
}
