import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

/// Goal inputs of a single diary day that change its budget and macro targets.
typedef DiaryDayGoalSignature = ({
  double goalKcal,
  bool isTrainingDay,
  bool isPauseDay,
});

/// Resolves the goal signature of [day], or `null` without [settings].
///
/// Comparing signatures keeps unrelated calorie goal writes from triggering a
/// dashboard reload.
DiaryDayGoalSignature? diaryDayGoalSignature(
  CalorieGoalSettings? settings,
  DateTime day,
) {
  if (settings == null) {
    return null;
  }
  return (
    goalKcal: settings.goalKcalForDay(day),
    isTrainingDay: settings.isTrainingDay(day),
    isPauseDay: settings.isPauseDay(day),
  );
}

/// What changes the dashboard of [day] when it changes in [settings]: the
/// mode of the week, and the goal signature of every day of the week up to
/// [day] (their types and goals add up to its carryover) and of the days
/// after it in its run (they count for the week balance). `null` without
/// [settings].
List<Object?>? diaryDashboardGoalSignatures(
  CalorieGoalSettings? settings,
  DateTime day,
) {
  if (settings == null) {
    return null;
  }
  return [
    settings.weekBalanceMode,
    for (final weekDay in buildRollingLocalDays(anchorDay: day))
      diaryDayGoalSignature(settings, weekDay),
    for (var offset = 1; offset < calorieGoalRunLengthDays; offset += 1)
      diaryDayGoalSignature(settings, addLocalDays(day, offset)),
  ];
}
