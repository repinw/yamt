import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_transition_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Result of evaluating a transition to a calculated goal.
typedef CalculatedGoalTransitionResult = ({
  bool isValid,
  bool goalChanged,
  CalorieGoalSettings? nextSettings,
  DateTime normalizedGoalStartDate,
});

/// Result of evaluating shifting a goal start date.
typedef ShiftGoalStartTransitionResult = ({
  bool isValid,
  bool goalStartChanged,
  CalorieGoalSettings? nextSettings,
});

/// Calculated goal transition logic on [CalorieGoalSettings].
extension CalorieGoalCalculatedTransitions on CalorieGoalSettings {
  /// Evaluates transitioning to a newly calculated goal.
  CalculatedGoalTransitionResult transitionToCalculatedGoal({
    required CalorieCalculatorProfile profile,
    required DateTime goalStartDate,
    required DateTime now,
    bool allowFutureGoalStart = false,
    bool? countGoalStartDayForLearning,
    bool archiveCurrentGoal = false,
  }) {
    final calculation = CalorieGoalCalculator.calculate(profile);
    var currentSettings = this;
    final normalizedToday = normalizeDiaryDay(now);
    final currentGoalEntry =
        currentSettings.activeGoalEntryForDay(now) ??
        currentSettings.latestGoalEntry;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    if (!allowFutureGoalStart &&
        normalizedGoalStartDate.isAfter(normalizedToday)) {
      return (
        isValid: false,
        goalChanged: false,
        nextSettings: null,
        normalizedGoalStartDate: normalizedGoalStartDate,
      );
    }
    final normalizedEffectiveDate =
        normalizedGoalStartDate.isAfter(normalizedToday)
        ? normalizedToday
        : normalizedGoalStartDate;
    final changedAt = goalChangeTimestamp(
      normalizedEffectiveDate: normalizedEffectiveDate,
      normalizedToday: normalizedToday,
      now: now,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate !=
            normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != calculation.finalGoalKcal ||
        goalStartDayTrackingChanged(
          currentGoalEntry: currentGoalEntry,
          normalizedGoalStartDate: normalizedGoalStartDate,
          countGoalStartDayForLearning: countGoalStartDayForLearning,
        ) ||
        !sameCalculatorProfile(currentGoalEntry?.calculatorProfile, profile) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;

    if (!goalChanged && !archiveCurrentGoal) {
      return (
        isValid: true,
        goalChanged: false,
        nextSettings: null,
        normalizedGoalStartDate: normalizedGoalStartDate,
      );
    }

    if (archiveCurrentGoal) {
      currentSettings = currentSettings.markActiveGoalEnded(
        changedAt,
        weightKg: profile.weightKg,
      );
    }

    final nextSettings = currentSettings.applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: calculation.finalGoalKcal,
      calculatorProfile: profile,
      countingStartDate: normalizedGoalStartDate,
      source: CalorieGoalSource.calculator,
      replaceFutureHistory: true,
      preserveSameDayGoalEntries: archiveCurrentGoal,
    );

    return (
      isValid: true,
      goalChanged: true,
      nextSettings: nextSettings,
      normalizedGoalStartDate: normalizedGoalStartDate,
    );
  }

  /// Evaluates shifting an active goal's counting start date.
  ShiftGoalStartTransitionResult shiftGoalStart({
    required DateTime goalStartDate,
    required DateTime now,
  }) {
    if (!hasGoal) {
      return (isValid: false, goalStartChanged: false, nextSettings: null);
    }

    final currentGoalEntry = activeGoalEntryForDay(now) ?? latestGoalEntry;
    final currentDailyKcalGoal =
        currentGoalEntry?.dailyKcalGoal ?? dailyKcalGoal;
    final currentCalculatorProfile =
        currentGoalEntry?.calculatorProfile ?? calculatorProfile;
    final currentSource = currentGoalEntry?.source ?? CalorieGoalSource.manual;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    final normalizedToday = normalizeDiaryDay(now);
    final normalizedEffectiveDate =
        normalizedGoalStartDate.isAfter(normalizedToday)
        ? normalizedToday
        : normalizedGoalStartDate;
    final changedAt = goalChangeTimestamp(
      normalizedEffectiveDate: normalizedEffectiveDate,
      normalizedToday: normalizedToday,
      now: now,
    );
    final goalStartChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate != normalizedGoalStartDate;

    if (!goalStartChanged) {
      return (isValid: true, goalStartChanged: false, nextSettings: null);
    }

    final nextSettings = applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: currentDailyKcalGoal,
      calculatorProfile: currentCalculatorProfile,
      countingStartDate: normalizedGoalStartDate,
      source: currentSource,
      replaceFutureHistory: true,
    );

    return (isValid: true, goalStartChanged: true, nextSettings: nextSettings);
  }
}
