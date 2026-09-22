import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_transition_helpers.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Result of evaluating a transition to a learned TDEE goal.
typedef LearnedTdeeGoalTransitionResult = ({
  bool isValid,
  bool goalChanged,
  CalorieGoalSettings? nextSettings,
});

/// Learned TDEE goal transition logic on [CalorieGoalSettings].
extension CalorieGoalLearnedTransitions on CalorieGoalSettings {
  /// Evaluates transitioning to a learned TDEE goal.
  LearnedTdeeGoalTransitionResult transitionToLearnedTdeeGoal({
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required double? targetWeightKg,
    required DateTime goalStartDate,
    required DateTime now,
    double? startWeightKg,
    DateTime? maintainUntil,
    bool? countGoalStartDayForLearning,
    bool archiveCurrentGoal = false,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
  }) {
    final learnedTdeeKcal = latestLearnedTdeeKcal;
    if (learnedTdeeKcal == null) {
      return (isValid: false, goalChanged: false, nextSettings: null);
    }
    if (goalMode != CalorieGoalMode.maintain &&
        (targetWeightKg == null || targetWeightKg <= 0)) {
      return (isValid: false, goalChanged: false, nextSettings: null);
    }

    final currentProfile =
        calculatorProfile ?? const CalorieCalculatorProfile.defaults();
    final nextProfile = currentProfile.copyWith(
      weightKg: startWeightKg,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
          ? 0
          : goalSpeedKgPerWeek,
      targetWeightKg: goalMode == CalorieGoalMode.maintain
          ? null
          : targetWeightKg,
      maintainUntil: goalMode == CalorieGoalMode.maintain
          ? maintainUntil
          : null,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
    );
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
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    final currentGoalEntry = activeGoalEntryForDay(now) ?? latestGoalEntry;
    final nextDailyKcalGoal =
        CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
          learnedTdeeKcal: learnedTdeeKcal,
          goalSpeedKgPerWeek: goalSpeedKgPerWeek,
          isLosing: goalMode == CalorieGoalMode.lose,
          isGaining: goalMode == CalorieGoalMode.gain,
        );
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate !=
            normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != nextDailyKcalGoal ||
        goalStartDayTrackingChanged(
          currentGoalEntry: currentGoalEntry,
          normalizedGoalStartDate: normalizedGoalStartDate,
          countGoalStartDayForLearning: countGoalStartDayForLearning,
        ) ||
        !sameCalculatorProfile(
          currentGoalEntry?.calculatorProfile,
          nextProfile,
        ) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;

    if (!goalChanged && !archiveCurrentGoal) {
      return (isValid: true, goalChanged: false, nextSettings: null);
    }

    var currentSettings = this;
    if (archiveCurrentGoal) {
      currentSettings = currentSettings.markActiveGoalEnded(
        changedAt,
        weightKg: startWeightKg,
      );
    }

    final nextSettings = currentSettings.applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: nextDailyKcalGoal,
      calculatorProfile: nextProfile,
      countingStartDate: normalizedGoalStartDate,
      source: CalorieGoalSource.calculator,
      replaceFutureHistory: true,
      preserveSameDayGoalEntries: archiveCurrentGoal,
    );

    return (isValid: true, goalChanged: true, nextSettings: nextSettings);
  }

  /// Evaluates applying a weekly check-in goal snapshot.
  CalorieGoalSettings applyWeeklyCheckInGoal({
    required DateTime completedAt,
    required double dailyKcalGoal,
    required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  }) {
    final snapshotSettings = applyGoalChange(
      changedAt: completedAt,
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: null,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
    );
    return CalorieGoalSettings(
      dailyKcalGoal: this.dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: snapshotSettings.calorieMathVersion,
      expectedActivityKcal: expectedActivityKcal,
      activityTrackingStartDate: snapshotSettings.activityTrackingStartDate,
      updatedAt: snapshotSettings.updatedAt,
      goalHistory: snapshotSettings.goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: snapshotSettings.skippedIntakeDayKeys,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
      trainingDayOverrides: trainingDayOverrides,
      pauseDayKeys: pauseDayKeys,
    );
  }
}
