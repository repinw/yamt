import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

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

/// The run that a weekly check-in plans, seen on the day of the check-in.
///
/// It answers which days the check-in may change: past days of a late
/// check-in and pause days keep their type.
@immutable
class CalorieCheckInRun {
  /// Creates the run of a check-in.
  const new({
    required this.days,
    required this.suggestedTrainingDays,
    required this.pauseDays,
    required this.pastDays,
  });

  /// The seven days of the run, first to last.
  final List<DateTime> days;

  /// Days of the run that train on the weekdays of the reviewed run.
  /// Past days and pause days keep their type.
  final Set<DateTime> suggestedTrainingDays;

  /// Days of the run that are pause days. They cannot train.
  final Set<DateTime> pauseDays;

  /// Days of the run before the check-in day, after a late check-in. They
  /// keep their type, because their calorie goals were already in use.
  final Set<DateTime> pastDays;

  /// Whether the check-in may change the type of [day]. Pause days and past
  /// days keep their type, so [suggestedTrainingDays] holds them as they are.
  bool canChangeDay(DateTime day) =>
      !pauseDays.contains(day) && !pastDays.contains(day);

  /// The days of [days] that keep their type and train.
  Set<DateTime> get fixedTrainingDays => {
    for (final day in suggestedTrainingDays)
      if (!canChangeDay(day)) day,
  };

  /// [trainingDays] picked for an earlier plan, limited to the days of this
  /// run that may change, plus the [fixedTrainingDays].
  Set<DateTime> keepTrainingDays(Set<DateTime> trainingDays) =>
      Set<DateTime>.unmodifiable({
        ...trainingDays.where((day) => days.contains(day) && canChangeDay(day)),
        ...fixedTrainingDays,
      });

  /// Rest days of the run with [trainingDays]. Pause days are neither.
  int restDayCount(Set<DateTime> trainingDays) =>
      days.length -
      trainingDays.length -
      pauseDays.difference(trainingDays).length;

  /// The choice that saves [trainingDays] as the training days of this run.
  CalorieRunTrainingChoice choice(Set<DateTime> trainingDays) =>
      (runDay: days.first, trainingDays: trainingDays);
}

/// Training days of the current 7-day run on [CalorieGoalSettings].
extension CalorieRunTraining on CalorieGoalSettings {
  /// The training plan of the run that contains [day].
  CalorieRunTrainingPlan runTrainingPlan(DateTime day) {
    final start = resolveCalorieGoalRunStartDate(settings: this, day: day);
    final days = [
      for (var offset = 0; offset < calorieGoalRunLengthDays; offset++)
        addLocalDays(start, offset),
    ];
    return CalorieRunTrainingPlan(
      days: List<DateTime>.unmodifiable(days),
      trainingDays: Set<DateTime>.unmodifiable(days.where(isTrainingDay)),
      pauseDays: Set<DateTime>.unmodifiable(days.where(isPauseDay)),
    );
  }

  /// The run that a check-in on [today] plans, suggesting the weekdays of
  /// the run that contains [reviewedDay].
  CalorieCheckInRun checkInRun({
    required DateTime reviewedDay,
    required DateTime today,
  }) {
    final checkInDay = normalizeLocalDay(today);
    final next = runTrainingPlan(checkInDay);
    final reviewedWeekdays = {
      for (final reviewedRunDay in runTrainingPlan(reviewedDay).trainingDays)
        reviewedRunDay.weekday,
    };
    return CalorieCheckInRun(
      days: next.days,
      suggestedTrainingDays: Set<DateTime>.unmodifiable({
        for (final runDay in next.days)
          if (runDay.isBefore(checkInDay) || next.pauseDays.contains(runDay)
              ? next.trainingDays.contains(runDay)
              : reviewedWeekdays.contains(runDay.weekday))
            runDay,
      }),
      pauseDays: next.pauseDays,
      pastDays: Set<DateTime>.unmodifiable({
        for (final runDay in next.days)
          if (runDay.isBefore(checkInDay)) runDay,
      }),
    );
  }

  /// Returns these settings with [trainingDays] as the training days of the
  /// run that contains [day]. Every other day of the run becomes a rest day.
  ///
  /// This plans per-day overrides: the weekly schedule stays for later runs.
  /// Every day of the run joins the plan and drops a day type change from
  /// the diary, so the run total is the base goal times seven again. Pause
  /// days keep their type.
  CalorieGoalSettings withRunTrainingDays(
    DateTime day, {
    required Set<DateTime> trainingDays,
  }) {
    final plan = runTrainingPlan(day);
    final wanted = {for (final day in trainingDays) localDayKey(day)};
    final overrides = Map<String, bool>.of(trainingDayOverrides);
    final unplanned = Map<String, bool>.of(unplannedTrainingDayOverrides);
    for (final runDay in plan.days) {
      if (plan.pauseDays.contains(runDay)) {
        continue;
      }
      final key = localDayKey(runDay);
      final isTraining = wanted.contains(key);
      unplanned.remove(key);
      if (isTraining == isScheduledTrainingDay(runDay)) {
        overrides.remove(key);
      } else {
        overrides[key] = isTraining;
      }
    }
    return copyWith(
      trainingDayOverrides: Map<String, bool>.unmodifiable(overrides),
      unplannedTrainingDayOverrides: Map<String, bool>.unmodifiable(unplanned),
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
        .isBefore(normalizeLocalDay(today))) {
      return null;
    }
    return withRunTrainingDays(
      training.runDay,
      trainingDays: training.trainingDays,
    );
  }
}
