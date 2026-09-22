import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

/// Sets a manual daily calorie goal.
Future<bool> setManualCalorieGoal({
  required CalorieGoalController controller,
  required double dailyKcalGoal,
  required DateTime now,
}) async {
  if (dailyKcalGoal <= 0) {
    return false;
  }
  final previous = await controller.currentSettings();
  final nextSettings = previous.applyGoalChange(
    changedAt: now,
    dailyKcalGoal: dailyKcalGoal,
    calculatorProfile: null,
  );
  return await controller.persistSettings(nextSettings);
}

/// Clears the active calorie goal.
Future<bool> clearCalorieGoal({
  required CalorieGoalController controller,
  required DateTime now,
}) async {
  final previous = await controller.currentSettings();
  return await controller.persistSettings(
    previous.applyGoalChange(
      changedAt: now,
      dailyKcalGoal: null,
      calculatorProfile: null,
    ),
  );
}

/// Persists target completion and reports whether it was newly reached.
Future<bool> markCalorieGoalReachedIfNeeded({
  required CalorieGoalController controller,
  required DateTime day,
  required double weightKg,
}) async {
  final previous = await controller.currentSettings();
  final active = previous.cycleAnchorEntryForDay(day);
  final profile = active?.calculatorProfile;
  final target = profile?.targetWeightKg;
  if (active == null ||
      profile == null ||
      target == null ||
      profile.goalMode == CalorieGoalMode.maintain) {
    return false;
  }
  if (active.reachedAt != null) {
    return active.reachedPromptHandledAt == null;
  }
  final reached = switch (profile.goalMode) {
    CalorieGoalMode.lose => weightKg <= target,
    CalorieGoalMode.gain => weightKg >= target,
    CalorieGoalMode.maintain => false,
  };
  if (!reached) {
    return false;
  }
  return await controller.persistSettings(
    previous.markActiveGoalReached(day, weightKg: weightKg),
  );
}

/// Records that the user explicitly answered the reached-goal prompt.
Future<bool> markCalorieGoalReachedPromptHandled({
  required CalorieGoalController controller,
  required DateTime now,
}) async {
  final previous = await controller.currentSettings();
  final next = previous.markGoalReachedPromptHandled(now);
  if (identical(previous, next)) {
    return true;
  }
  return await controller.persistSettings(next);
}

/// Sets pending weekly check-in snapshot.
Future<bool> setPendingGoalWeeklyCheckIn({
  required CalorieGoalController controller,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) async {
  final previous = await controller.currentSettings();
  return await controller.persistSettings(
    previous.copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
  );
}

/// Dismisses pending weekly check-in snapshot.
Future<bool> dismissPendingGoalWeeklyCheckIn({
  required CalorieGoalController controller,
  required DateTime now,
  DateTime? dismissedAt,
}) async {
  final previous = await controller.currentSettings();
  if (previous.pendingWeeklyCheckIn == null) {
    return true;
  }
  return await controller.persistSettings(
    previous.dismissPendingWeeklyCheckIn(dismissedAt ?? now),
  );
}

/// Clears pending weekly check-in snapshot.
Future<bool> clearPendingGoalWeeklyCheckIn({
  required CalorieGoalController controller,
}) async {
  final previous = await controller.currentSettings();
  if (previous.pendingWeeklyCheckIn == null) {
    return true;
  }
  return await controller.persistSettings(
    previous.copyWithPendingWeeklyCheckIn(null),
  );
}

/// Sets skipped intake day after validating entries.
Future<bool> setCalorieSkippedIntakeDay({
  required CalorieGoalController controller,
  required CalorieLogRepositoryContract logRepository,
  required DateTime day,
  required bool isSkipped,
  required DateTime now,
}) async {
  if (isSkipped) {
    final entries = await logRepository.readEntriesForDay(day);
    if (entries.isNotEmpty) {
      return false;
    }
  }
  final previous = await controller.currentSettings();
  if (previous.isSkippedIntakeDay(day) == isSkipped) {
    return true;
  }
  final nextSettings = previous
      .setSkippedIntakeDay(day: day, isSkipped: isSkipped)
      .invalidateWeeklyCheckInSnapshotsFromDay(day: day, invalidatedAt: now);
  return await controller.persistSettings(nextSettings);
}

/// Clears skipped intake day for a date.
Future<bool> clearCalorieSkippedIntakeDay({
  required CalorieGoalController controller,
  required CalorieLogRepositoryContract logRepository,
  required DateTime day,
  required DateTime now,
}) async {
  final previous = await controller.currentSettings();
  if (!previous.isSkippedIntakeDay(day)) {
    return true;
  }
  return await setCalorieSkippedIntakeDay(
    controller: controller,
    logRepository: logRepository,
    day: day,
    isSkipped: false,
    now: now,
  );
}

/// Invalidates weekly check-in snapshots from the specified day.
Future<bool> invalidateGoalWeeklyCheckInSnapshots({
  required CalorieGoalController controller,
  required DateTime day,
  required DateTime now,
}) async {
  final previous = await controller.currentSettings();
  final nextSettings = previous.invalidateWeeklyCheckInSnapshotsFromDay(
    day: day,
    invalidatedAt: now,
  );
  if (identical(previous, nextSettings)) {
    return true;
  }
  return await controller.persistSettings(nextSettings);
}

/// Toggles training day override for a day.
Future<bool> toggleCalorieTrainingDay({
  required CalorieGoalController controller,
  required DateTime day,
}) async {
  final previous = await controller.currentSettings();
  final nextSettings = previous.toggleTrainingDay(day);
  return await controller.persistSettings(nextSettings);
}

/// Updates weekly training days and kcal offset.
Future<bool> updateCalorieTrainingSchedule({
  required CalorieGoalController controller,
  required List<int> trainingWeekdays,
  required double trainingDayKcalOffset,
}) async {
  final previous = await controller.currentSettings();
  final nextProfile = previous.calculatorProfile?.copyWith(
    trainingWeekdays: trainingWeekdays,
    trainingDayKcalOffset: trainingDayKcalOffset,
  );
  final nextSettings = previous.copyWith(
    trainingWeekdays: trainingWeekdays,
    trainingDayKcalOffset: trainingDayKcalOffset,
    calculatorProfile: nextProfile,
  );
  return await controller.persistSettings(nextSettings);
}

/// Sets pause day for a specific date.
Future<bool> setCaloriePauseDay({
  required CalorieGoalController controller,
  required DateTime day,
  required bool isPause,
}) async {
  final previous = await controller.currentSettings();
  final nextSettings = previous.setPauseDay(day: day, isPause: isPause);
  return await controller.persistSettings(nextSettings);
}
