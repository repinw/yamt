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
