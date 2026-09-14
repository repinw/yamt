import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Calorie cycling and training day extension for [CalorieGoalSettings].
extension CalorieGoalSettingsCycling on CalorieGoalSettings {
  /// Whether [day] is a training day taking scheduled weekdays and overrides
  /// into account.
  bool isTrainingDay(DateTime day) {
    final dayKey = diaryDayKey(day);
    if (trainingDayOverrides.containsKey(dayKey)) {
      return trainingDayOverrides[dayKey]!;
    }
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
  double goalKcalForDay(DateTime day) {
    final base = baseGoalKcalForDay(day);
    if (base <= 0) {
      return base;
    }
    final activeProfile =
        goalEntryForDay(day)?.calculatorProfile ?? calculatorProfile;
    final configuredOffset =
        activeProfile?.trainingDayKcalOffset ?? trainingDayKcalOffset;
    final weekdays = activeProfile?.trainingWeekdays ?? trainingWeekdays;
    final isTraining = isTrainingDay(day);

    final resolvedKcal = _resolveCyclingKcal(
      base: base,
      configuredOffset: configuredOffset,
      trainingDaysCount: weekdays.length,
      isTraining: isTraining,
    );
    return resolvedKcal.clamp(minimumDailyCalorieBudgetKcal, double.infinity);
  }

  double _resolveCyclingKcal({
    required double base,
    required double configuredOffset,
    required int trainingDaysCount,
    required bool isTraining,
  }) {
    if (trainingDaysCount <= 0) {
      if (!isTraining) return base;
      final offset = configuredOffset > 0
          ? configuredOffset
          : defaultTrainingDayKcalOffset;
      return base + offset;
    }
    if (configuredOffset <= 0 || trainingDaysCount >= 7) {
      return isTraining && configuredOffset > 0
          ? base + configuredOffset
          : base;
    }
    if (isTraining) return base + configuredOffset;
    final restDaysCount = 7 - trainingDaysCount;
    final restDayReduction =
        (trainingDaysCount * configuredOffset) / restDaysCount;
    return base - restDayReduction;
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
