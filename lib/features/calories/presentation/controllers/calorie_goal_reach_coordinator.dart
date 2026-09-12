import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_reached_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_reach_coordinator.g.dart';

/// Coordinates the complete calorie-owned flow after a weight was recorded.
@riverpod
CalorieGoalReachCoordinator calorieGoalReachCoordinator(Ref ref) {
  final controller = ref.watch(calorieGoalControllerProvider.notifier);
  return CalorieGoalReachCoordinator(
    markReached: controller.markGoalReachedIfNeeded,
    markPromptHandled: controller.markGoalReachedPromptHandled,
    loadSettings: () => ref.read(calorieGoalControllerProvider.future),
  );
}

/// Public Calories presentation edge for goal-reached handling.
class CalorieGoalReachCoordinator {
  /// Creates the coordinator with its calorie-owned actions.
  const CalorieGoalReachCoordinator({
    required Future<bool> Function({
      required DateTime day,
      required double weightKg,
    })
    markReached,
    required Future<bool> Function() markPromptHandled,
    required Future<CalorieGoalSettings> Function() loadSettings,
  }) : _markReached = markReached,
       _markPromptHandled = markPromptHandled,
       _loadSettings = loadSettings;

  final Future<bool> Function({
    required DateTime day,
    required double weightKg,
  })
  _markReached;
  final Future<bool> Function() _markPromptHandled;
  final Future<CalorieGoalSettings> Function() _loadSettings;

  /// Handles a recorded weight, including the one-time prompt and new goal UI.
  Future<void> handleRecordedWeight({
    required BuildContext context,
    required DateTime day,
    required double weightKg,
  }) async {
    final newlyReached = await _markReached(day: day, weightKg: weightKg);
    if (!newlyReached || !context.mounted) return;

    final action = await showCalorieGoalReachedDialog(context);
    if (action == null) return;

    await _markPromptHandled();
    if (action != CalorieGoalReachedAction.newGoal || !context.mounted) return;

    final settings = await _loadSettings();
    if (!context.mounted) return;
    await showCalorieGoalCalculatorSheet(
      context,
      initialSettings: settings,
      startsNewGoal: true,
      currentWeightKg: weightKg,
    );
  }
}
