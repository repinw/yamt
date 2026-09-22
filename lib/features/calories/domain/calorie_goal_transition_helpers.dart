import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Checks if two calculator profiles are structurally equivalent.
bool sameCalculatorProfile(
  CalorieCalculatorProfile? left,
  CalorieCalculatorProfile? right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return left == right;
  }
  return left.sex == right.sex &&
      left.weightKg == right.weightKg &&
      left.heightCm == right.heightCm &&
      left.ageYears == right.ageYears &&
      left.activityLevel == right.activityLevel &&
      left.goalMode == right.goalMode &&
      left.goalSpeedKgPerWeek == right.goalSpeedKgPerWeek &&
      left.targetWeightKg == right.targetWeightKg &&
      left.maintainUntil == right.maintainUntil &&
      left.trainingDayKcalOffset == right.trainingDayKcalOffset &&
      sameIntList(left.trainingWeekdays, right.trainingWeekdays);
}

/// Checks if two integer lists contain the same elements in order.
bool sameIntList(List<int> left, List<int> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

/// Resolves the change timestamp for a goal mutation.
DateTime goalChangeTimestamp({
  required DateTime normalizedEffectiveDate,
  required DateTime normalizedToday,
  required DateTime now,
  bool? countGoalStartDayForLearning,
}) {
  if (isSameDiaryDay(normalizedEffectiveDate, normalizedToday)) {
    if (countGoalStartDayForLearning == true) {
      return normalizedEffectiveDate;
    }
    return now;
  }
  return normalizedEffectiveDate;
}

/// Checks whether the goal start tracking configuration changed.
bool goalStartDayTrackingChanged({
  required CalorieGoalHistoryEntry? currentGoalEntry,
  required DateTime normalizedGoalStartDate,
  required bool? countGoalStartDayForLearning,
}) {
  if (countGoalStartDayForLearning == null || currentGoalEntry == null) {
    return false;
  }
  if (!isSameDiaryDay(
    currentGoalEntry.effectiveCountingStartDate,
    normalizedGoalStartDate,
  )) {
    return false;
  }
  return goalEntryCountsStartDay(currentGoalEntry) !=
      countGoalStartDayForLearning;
}

/// Determines whether a goal history entry counts its start day for learning.
bool goalEntryCountsStartDay(CalorieGoalHistoryEntry entry) {
  if (!isSameDiaryDay(entry.effectiveDate, entry.effectiveCountingStartDate)) {
    return true;
  }
  final changedAt = entry.effectiveChangedAt;
  return changedAt.hour == 0 &&
      changedAt.minute == 0 &&
      changedAt.second == 0 &&
      changedAt.millisecond == 0 &&
      changedAt.microsecond == 0;
}
