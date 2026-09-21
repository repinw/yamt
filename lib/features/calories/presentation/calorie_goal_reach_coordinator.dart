import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_reached_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_new_goal_flow.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_reach_coordinator.g.dart';

/// Provides the coordinator for goal-reached handling.
@riverpod
CalorieGoalReachCoordinator calorieGoalReachCoordinator(Ref ref) {
  return const CalorieGoalReachCoordinator();
}

/// Public Calories presentation edge for goal-reached handling.
class CalorieGoalReachCoordinator {
  /// Creates the coordinator.
  const new();

  /// Handles a recorded weight, including the one-time prompt and new goal UI.
  Future<void> handleRecordedWeight({
    required BuildContext context,
    required DateTime day,
    required double weightKg,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    // Keeps the auto-dispose goal controller alive during the whole flow.
    final subscription = container.listen(
      calorieGoalControllerProvider,
      (_, _) {},
    );
    try {
      final controller = container.read(calorieGoalControllerProvider.notifier);
      final newlyReached = await controller.markGoalReachedIfNeeded(
        day: day,
        weightKg: weightKg,
      );
      if (!newlyReached || !context.mounted) {
        return;
      }
      final action = await showCalorieGoalReachedDialog(context);
      if (action == null) {
        return;
      }
      await controller.markGoalReachedPromptHandled();
      if (action != CalorieGoalReachedAction.newGoal || !context.mounted) {
        return;
      }
      await showCalorieNewGoalSheet(context, currentWeightKg: weightKg);
    } finally {
      subscription.close();
    }
  }
}
