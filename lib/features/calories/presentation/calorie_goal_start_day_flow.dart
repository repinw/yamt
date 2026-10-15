import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_start_food_tracking_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_start_picker.dart';

/// Asks before a goal save whether today's food counts for learning, when
/// [goalStartDate] is today.
///
/// Returns `null` to stop the save: when the user cancels, and when today's
/// entries cannot be read, which shows [failedMessage] (#710). Otherwise
/// `countsToday` is the answer, or `null` when the goal starts on another
/// day.
Future<({bool? countsToday})?> askGoalStartDayForLearning(
  BuildContext context, {
  required DateTime goalStartDate,
  required String failedMessage,
}) async {
  final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
  if (!CalorieGoalStartPicker.isSameDay(goalStartDate, today)) {
    return (countsToday: null);
  }
  final container = ProviderScope.containerOf(context, listen: false);
  // Keeps the auto-dispose goal controller alive while it reads.
  final subscription = container.listen(
    calorieGoalControllerProvider,
    (_, _) {},
  );
  final int? entryCount;
  try {
    entryCount = await container
        .read(calorieGoalControllerProvider.notifier)
        .readEntryCountForDay(today);
  } finally {
    subscription.close();
  }
  if (!context.mounted) {
    return null;
  }
  if (entryCount == null) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(failedMessage, tone: AppSnackBarTone.error);
    return null;
  }
  final countsToday = await showCalorieGoalStartFoodTrackingDialog(
    context,
    entryCount: entryCount,
  );
  return countsToday == null ? null : (countsToday: countsToday);
}
