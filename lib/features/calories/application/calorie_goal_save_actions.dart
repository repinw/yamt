import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/calorie_goal_seed_weight_flow.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculated_transitions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_learned_transitions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

/// Coordinates saving a calculated calorie goal.
Future<bool> saveCalculatedCalorieGoal({
  required CalorieGoalController controller,
  required Ref ref,
  required CalorieCalculatorProfile profile,
  required DateTime goalStartDate,
  required DateTime now,
  bool allowFutureGoalStart = false,
  bool? countGoalStartDayForLearning,
  bool archiveCurrentGoal = false,
}) async {
  final previousSettings = await controller.currentSettings();
  final transition = previousSettings.transitionToCalculatedGoal(
    profile: profile,
    goalStartDate: goalStartDate,
    now: now,
    allowFutureGoalStart: allowFutureGoalStart,
    countGoalStartDayForLearning: countGoalStartDayForLearning,
    archiveCurrentGoal: archiveCurrentGoal,
  );
  if (!transition.isValid) {
    return false;
  }
  if (!transition.goalChanged && !archiveCurrentGoal) {
    return true;
  }
  final nextSettings = transition.nextSettings;
  if (nextSettings == null) {
    return true;
  }
  final saved = await controller.persistSettings(nextSettings);
  if (!saved || !ref.mounted) {
    return saved;
  }
  await seedCalculatorWeightIfMissing(
    ref: ref,
    day: transition.normalizedGoalStartDate,
    weightKg: profile.weightKg,
    onSeedSaved: controller.invalidateWeeklyCheckInSnapshotsFromDay,
  );
  return true;
}

/// Coordinates shifting an active goal's counting start date.
Future<bool> shiftCalorieGoalStart({
  required CalorieGoalController controller,
  required DateTime goalStartDate,
  required DateTime now,
}) async {
  final previousSettings = await controller.currentSettings();
  final transition = previousSettings.shiftGoalStart(
    goalStartDate: goalStartDate,
    now: now,
  );
  if (!transition.isValid) {
    return false;
  }
  if (!transition.goalStartChanged) {
    return true;
  }
  final nextSettings = transition.nextSettings;
  if (nextSettings == null) {
    return true;
  }
  return await controller.persistSettings(nextSettings);
}

/// Coordinates saving a learned TDEE goal and reporting whether data changed.
Future<LearnedTdeeGoalSaveResult> saveLearnedTdeeCalorieGoal({
  required CalorieGoalController controller,
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
}) async {
  final previousSettings = await controller.currentSettings();
  final transition = previousSettings.transitionToLearnedTdeeGoal(
    goalMode: goalMode,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    targetWeightKg: targetWeightKg,
    goalStartDate: goalStartDate,
    now: now,
    startWeightKg: startWeightKg,
    maintainUntil: maintainUntil,
    countGoalStartDayForLearning: countGoalStartDayForLearning,
    archiveCurrentGoal: archiveCurrentGoal,
    trainingWeekdays: trainingWeekdays,
    trainingDayKcalOffset: trainingDayKcalOffset,
  );
  if (!transition.isValid) {
    return (saved: false, goalChanged: false);
  }
  if (!transition.goalChanged && !archiveCurrentGoal) {
    return (saved: true, goalChanged: false);
  }
  final nextSettings = transition.nextSettings;
  if (nextSettings == null) {
    return (saved: true, goalChanged: false);
  }
  final saved = await controller.persistSettings(nextSettings);
  return (saved: saved, goalChanged: saved);
}

/// Coordinates applying a weekly check-in goal snapshot.
Future<bool> saveWeeklyCheckInCalorieGoal({
  required CalorieGoalController controller,
  required DateTime completedAt,
  required double dailyKcalGoal,
  required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
}) async {
  final previousSettings = await controller.currentSettings();
  final nextSettings = previousSettings.applyWeeklyCheckInGoal(
    completedAt: completedAt,
    dailyKcalGoal: dailyKcalGoal,
    weeklyCheckInSnapshot: weeklyCheckInSnapshot,
  );
  return await controller.persistSettings(nextSettings);
}
