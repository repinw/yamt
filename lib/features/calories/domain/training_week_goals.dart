/// Daily goals of a week with training and rest days.
typedef TrainingWeekGoals = ({double trainingDayKcal, double restDayKcal});

/// Spreads [baseGoalKcal] over training and rest days.
///
/// [baseGoalKcal] is the daily average of the week and already holds the
/// training sessions (see `CalorieGoalCalculator`). A training day gets
/// [sessionKcal] more than a rest day, so the session lands on the day it
/// burns; the weekly total stays [baseGoalKcal] times seven. The split only
/// applies when the week has both kinds of days.
TrainingWeekGoals resolveTrainingWeekGoals({
  required double baseGoalKcal,
  required int trainingDays,
  required double sessionKcal,
}) {
  final restDays = DateTime.daysPerWeek - trainingDays;
  if (trainingDays <= 0 || restDays <= 0) {
    return (trainingDayKcal: baseGoalKcal, restDayKcal: baseGoalKcal);
  }
  return (
    trainingDayKcal:
        baseGoalKcal + sessionKcal * restDays / DateTime.daysPerWeek,
    restDayKcal:
        baseGoalKcal - sessionKcal * trainingDays / DateTime.daysPerWeek,
  );
}

/// Average kcal a day that [trainingDays] sessions a week of [sessionKcal]
/// each add to the daily energy use.
double trainingKcalPerDay({
  required int trainingDays,
  required double sessionKcal,
}) {
  if (trainingDays <= 0 || sessionKcal <= 0) {
    return 0;
  }
  return trainingDays * sessionKcal / DateTime.daysPerWeek;
}
