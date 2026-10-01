import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Training days that the user picked for the run that contains `runDay`.
typedef CalorieRunTrainingChoice = ({
  DateTime runDay,
  Set<DateTime> trainingDays,
});

/// The training and pause days of one 7-day run.
@immutable
class CalorieRunTrainingPlan {
  /// Creates the plan of a run.
  const new({
    required this.days,
    required this.trainingDays,
    required this.pauseDays,
  });

  /// The days of the run, first to last.
  final List<DateTime> days;

  /// The days of the run that are training days.
  final Set<DateTime> trainingDays;

  /// The days of the run that are pause days. Their type stays.
  final Set<DateTime> pauseDays;

  /// The last day of the run.
  DateTime get lastDay => days.last;

  /// The training days in run order.
  List<DateTime> get orderedTrainingDays => [
    for (final day in days)
      if (trainingDays.contains(day)) day,
  ];
}

/// Training days of the current 7-day run on [CalorieGoalSettings].
extension CalorieRunTraining on CalorieGoalSettings {
  /// The training plan of the run that contains [day].
  CalorieRunTrainingPlan runTrainingPlan(DateTime day) {
    final start = resolveCalorieGoalRunStartDate(settings: this, day: day);
    final days = [
      for (var offset = 0; offset < calorieGoalRunLengthDays; offset++)
        addDiaryDays(start, offset),
    ];
    return CalorieRunTrainingPlan(
      days: List<DateTime>.unmodifiable(days),
      trainingDays: Set<DateTime>.unmodifiable(days.where(isTrainingDay)),
      pauseDays: Set<DateTime>.unmodifiable(days.where(isPauseDay)),
    );
  }

  /// Returns these settings with [trainingDays] as the training days of the
  /// run that contains [day]. Every other day of the run becomes a rest day.
  ///
  /// Like a day type change in the diary, this sets per-day overrides: the
  /// weekly schedule stays for later runs. Pause days keep their type.
  CalorieGoalSettings withRunTrainingDays(
    DateTime day, {
    required Set<DateTime> trainingDays,
  }) {
    final plan = runTrainingPlan(day);
    final wanted = {for (final day in trainingDays) diaryDayKey(day)};
    final overrides = Map<String, bool>.of(trainingDayOverrides);
    for (final runDay in plan.days) {
      if (plan.pauseDays.contains(runDay)) {
        continue;
      }
      final key = diaryDayKey(runDay);
      final isTraining = wanted.contains(key);
      if (isTraining == isScheduledTrainingDay(runDay)) {
        overrides.remove(key);
      } else {
        overrides[key] = isTraining;
      }
    }
    return copyWith(
      trainingDayOverrides: Map<String, bool>.unmodifiable(overrides),
    );
  }

  /// Returns these settings with the [training] days of its run, or `null`
  /// when that run ended before [today]. A sheet left open into a later run
  /// must not rewrite days whose goals were already in use.
  CalorieGoalSettings? withPlannedRunTrainingDays(
    CalorieRunTrainingChoice training, {
    required DateTime today,
  }) {
    if (runTrainingPlan(training.runDay).lastDay
        .isBefore(normalizeDiaryDay(today))) {
      return null;
    }
    return withRunTrainingDays(
      training.runDay,
      trainingDays: training.trainingDays,
    );
  }
}
