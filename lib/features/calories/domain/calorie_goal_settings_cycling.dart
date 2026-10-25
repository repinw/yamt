import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/training_week_goals.dart';

/// Calorie cycling and training day extension for [CalorieGoalSettings].
extension CalorieGoalSettingsCycling on CalorieGoalSettings {
  /// Whether [day] is a training day: the plan, or the day type the diary
  /// set outside it.
  bool isTrainingDay(DateTime day) {
    return unplannedTrainingDayOverrides[localDayKey(day)] ??
        isPlannedTrainingDay(day);
  }

  /// Whether the plan makes [day] a training day: the weekly schedule with
  /// the planned overrides of single days.
  bool isPlannedTrainingDay(DateTime day) {
    return trainingDayOverrides[localDayKey(day)] ??
        isScheduledTrainingDay(day);
  }

  /// Whether the weekly training schedule makes [day] a training day,
  /// without the per-day overrides.
  bool isScheduledTrainingDay(DateTime day) {
    final activeProfile =
        goalEntryForDay(day)?.calculatorProfile ?? calculatorProfile;
    final weekdays = activeProfile?.trainingWeekdays ?? trainingWeekdays;
    return weekdays.contains(day.weekday);
  }

  /// Whether [day] is marked as a pause/exception day.
  bool isPauseDay(DateTime day) {
    return pauseDayKeys.contains(localDayKey(day));
  }

  /// Effective goal kcal for day taking training days / rest day cycling into
  /// account.
  ///
  /// The base goal is the daily average and already holds the planned
  /// training sessions. A training day gets one session (the configured
  /// offset) more than a rest day. The planned training days of the 7-day run
  /// split it, so with the plan the run total stays the base goal times
  /// seven (see `resolveTrainingWeekGoals`). A day type changed outside the
  /// plan gains or loses one session on that day only, and the other days
  /// keep their goals.
  double goalKcalForDay(DateTime day) {
    final base = baseGoalKcalForDay(day);
    if (base <= 0) {
      return base;
    }
    final sessionKcal = trainingSessionKcalForDay(day);
    final restDayKcal =
        base -
        trainingKcalPerDay(
          trainingDays: _plannedTrainingDaysInRun(day),
          sessionKcal: sessionKcal,
        );
    final resolvedKcal = isTrainingDay(day)
        ? restDayKcal + sessionKcal
        : restDayKcal;
    return resolvedKcal.clamp(minimumDailyCalorieBudgetKcal, double.infinity);
  }

  /// kcal of one training session on [day]: the offset of the active
  /// calculator profile, or the default offset without a weekly schedule.
  double trainingSessionKcalForDay(DateTime day) {
    final activeProfile =
        goalEntryForDay(day)?.calculatorProfile ?? calculatorProfile;
    final configuredOffset =
        activeProfile?.trainingDayKcalOffset ?? trainingDayKcalOffset;
    final weekdays = activeProfile?.trainingWeekdays ?? trainingWeekdays;
    if (configuredOffset > 0) {
      return configuredOffset;
    }
    return weekdays.isEmpty ? defaultTrainingDayKcalOffset : 0.0;
  }

  /// Number of planned training days in the 7-day run of [day]. Before a
  /// goal starts counting there is no run, and the weekly schedule counts
  /// instead.
  int _plannedTrainingDaysInRun(DateTime day) {
    if (countingGoalEntryForDay(day) == null) {
      final activeProfile =
          goalEntryForDay(day)?.calculatorProfile ?? calculatorProfile;
      return (activeProfile?.trainingWeekdays ?? trainingWeekdays).length;
    }
    final runStart = resolveCalorieGoalRunStartDate(settings: this, day: day);
    var count = 0;
    for (var offset = 0; offset < calorieGoalRunLengthDays; offset++) {
      if (isPlannedTrainingDay(addLocalDays(runStart, offset))) {
        count++;
      }
    }
    return count;
  }

  /// Toggles training day status for [day] outside the plan; toggling back
  /// to the plan drops the change.
  CalorieGoalSettings toggleTrainingDay(DateTime day) {
    final dayKey = localDayKey(day);
    final wantsTraining = !isTrainingDay(day);
    final nextOverrides = Map<String, bool>.from(unplannedTrainingDayOverrides);
    if (wantsTraining == isPlannedTrainingDay(day)) {
      nextOverrides.remove(dayKey);
    } else {
      nextOverrides[dayKey] = wantsTraining;
    }
    return copyWith(unplannedTrainingDayOverrides: nextOverrides);
  }

  /// Sets whether [day] is a pause day.
  CalorieGoalSettings setPauseDay({
    required DateTime day,
    required bool isPause,
  }) {
    final dayKey = localDayKey(day);
    final nextKeys = List<String>.from(pauseDayKeys);
    if (isPause && !nextKeys.contains(dayKey)) {
      nextKeys.add(dayKey);
    } else if (!isPause && nextKeys.contains(dayKey)) {
      nextKeys.remove(dayKey);
    }
    nextKeys.sort();
    return copyWith(pauseDayKeys: List<String>.unmodifiable(nextKeys));
  }
}
