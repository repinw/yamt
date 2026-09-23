/// Daily goals of a week in which training days borrow from rest days.
typedef TrainingWeekGoals = ({double trainingDayKcal, double restDayKcal});

/// Spreads [baseGoalKcal] over training and rest days.
///
/// Training days get [offsetKcal] more, rest days give the same sum back, so
/// the weekly total stays the same. Cycling only applies when the week has
/// both kinds of days.
TrainingWeekGoals resolveTrainingWeekGoals({
  required double baseGoalKcal,
  required int trainingDays,
  required double offsetKcal,
}) {
  final restDays = DateTime.daysPerWeek - trainingDays;
  if (trainingDays <= 0 || restDays <= 0) {
    return (trainingDayKcal: baseGoalKcal, restDayKcal: baseGoalKcal);
  }
  return (
    trainingDayKcal: baseGoalKcal + offsetKcal,
    restDayKcal: baseGoalKcal - (trainingDays * offsetKcal) / restDays,
  );
}
