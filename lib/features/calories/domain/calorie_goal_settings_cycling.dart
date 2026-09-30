import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/training_week_goals.dart';

/// Calorie cycling and training day extension for [CalorieGoalSettings].
extension CalorieGoalSettingsCycling on CalorieGoalSettings {
  /// Whether [day] is a training day taking scheduled weekdays and overrides
  /// into account.
  bool isTrainingDay(DateTime day) {
    final dayKey = diaryDayKey(day);
    if (trainingDayOverrides.containsKey(dayKey)) {
      return trainingDayOverrides[dayKey]!;
    }
    return isScheduledTrainingDay(day);
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
    return pauseDayKeys.contains(diaryDayKey(day));
  }

  /// Effective goal kcal for day taking training days / rest day cycling into
  /// account.
  ///
  /// The base goal is the daily average and already holds the planned
  /// training sessions. A training day gets one session (the configured
  /// offset) more than a rest day of the same 7-day run, so the run total
  /// stays the base goal times seven. The training days are counted in the
  /// run with the per-day overrides, so a changed day type moves calories
  /// between the days of its run; the carryover passes on what past days of
  /// the run got differently.
  double goalKcalForDay(DateTime day) {
    final base = baseGoalKcalForDay(day);
    if (base <= 0) {
      return base;
    }
    final weekGoals = resolveTrainingWeekGoals(
      baseGoalKcal: base,
      trainingDays: _trainingDaysInRun(day),
      sessionKcal: trainingSessionKcalForDay(day),
    );
    final resolvedKcal = isTrainingDay(day)
        ? weekGoals.trainingDayKcal
        : weekGoals.restDayKcal;
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

  /// Number of training days in the 7-day run of [day]. Before a goal starts
  /// counting there is no run, and the weekly schedule counts instead.
  int _trainingDaysInRun(DateTime day) {
    if (countingGoalEntryForDay(day) == null) {
      final activeProfile =
          goalEntryForDay(day)?.calculatorProfile ?? calculatorProfile;
      return (activeProfile?.trainingWeekdays ?? trainingWeekdays).length;
    }
    final runStart = resolveCalorieGoalRunStartDate(settings: this, day: day);
    var count = 0;
    for (var offset = 0; offset < calorieGoalRunLengthDays; offset++) {
      if (isTrainingDay(addDiaryDays(runStart, offset))) {
        count++;
      }
    }
    return count;
  }

  /// Toggles training day status for [day].
  CalorieGoalSettings toggleTrainingDay(DateTime day) {
    final dayKey = diaryDayKey(day);
    final currentlyTraining = isTrainingDay(day);
    final nextOverrides = Map<String, bool>.from(trainingDayOverrides);
    nextOverrides[dayKey] = !currentlyTraining;
    return copyWith(trainingDayOverrides: nextOverrides);
  }

  /// Sets whether [day] is a pause day.
  CalorieGoalSettings setPauseDay({
    required DateTime day,
    required bool isPause,
  }) {
    final dayKey = diaryDayKey(day);
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
