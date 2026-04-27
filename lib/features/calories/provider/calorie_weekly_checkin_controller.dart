import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';

part 'calorie_weekly_checkin_controller.g.dart';

/// Defines calorie weekly check in controller.
@riverpod
class CalorieWeeklyCheckInController extends _$CalorieWeeklyCheckInController {
  @override
  AsyncValue<void> build() {
    // This controller is read from dialog callbacks without being watched.
    // Keep the instance alive after first creation so a captured notifier
    // does not get disposed before the user presses Apply/Later.
    ref.keepAlive();
    return const AsyncData(null);
  }

  /// Sync pending weekly check in.
  Future<bool> syncPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) async {
    final settings = await ref.read(calorieGoalControllerProvider.future);
    if (!ref.mounted) {
      return false;
    }
    final currentPending = settings.pendingWeeklyCheckIn;
    if (currentPending != null &&
        currentPending.windowKey == pendingWeeklyCheckIn.windowKey &&
        currentPending.dismissedAt == pendingWeeklyCheckIn.dismissedAt) {
      return true;
    }
    return ref
        .read(calorieGoalControllerProvider.notifier)
        .setPendingWeeklyCheckIn(pendingWeeklyCheckIn);
  }

  /// Dismiss pending weekly check in.
  Future<bool> dismissPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) async {
    state = const AsyncLoading();
    final synced = await syncPendingWeeklyCheckIn(pendingWeeklyCheckIn);
    if (!ref.mounted) {
      return false;
    }
    if (!synced) {
      state = AsyncError(
        StateError('Failed to persist pending weekly check-in.'),
        StackTrace.empty,
      );
      return false;
    }

    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .dismissPendingWeeklyCheckIn();
    if (!ref.mounted) {
      return saved;
    }
    state = const AsyncData(null);
    return saved;
  }

  /// Apply weekly check in.
  Future<bool> applyWeeklyCheckIn(
    CalorieWeeklyCheckInViewModel viewModel,
  ) async {
    final pendingWeeklyCheckIn = viewModel.pendingWeeklyCheckIn;
    final calculation = viewModel.calculation;
    if (pendingWeeklyCheckIn == null ||
        calculation == null ||
        viewModel.isBlocked) {
      return false;
    }

    state = const AsyncLoading();
    final synced = await syncPendingWeeklyCheckIn(pendingWeeklyCheckIn);
    if (!ref.mounted) {
      return false;
    }
    if (!synced) {
      state = AsyncError(
        StateError('Failed to persist pending weekly check-in.'),
        StackTrace.empty,
      );
      return false;
    }

    final goalController = ref.read(calorieGoalControllerProvider.notifier);
    final savedSnapshot = await goalController.saveWeeklyCheckInGoal(
      completedAt: pendingWeeklyCheckIn.dueDate,
      dailyKcalGoal: calculation.newGoalKcal,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: pendingWeeklyCheckIn.windowStartDate,
        windowEndDate: pendingWeeklyCheckIn.windowEndDate,
        trendWeightChangePerDay: calculation.trendWeightChangePerDay,
        calculatedTrueTdeeKcal: calculation.calculatedTrueTdeeKcal,
        averageActiveKcal: calculation.lastWeekAverageActiveKcal,
        lowConfidence: viewModel.lowConfidence,
      ),
    );

    if (!ref.mounted) {
      return savedSnapshot;
    }
    if (!savedSnapshot) {
      state = AsyncError(
        StateError('Failed to persist learned TDEE cache.'),
        StackTrace.empty,
      );
      return false;
    }

    final saved = await goalController.dismissPendingWeeklyCheckIn();

    if (!ref.mounted) {
      return saved;
    }
    state = const AsyncData(null);
    return saved;
  }

  /// Set skipped intake day.
  Future<bool> setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) {
    return ref
        .read(calorieGoalControllerProvider.notifier)
        .setSkippedIntakeDay(day: day, isSkipped: isSkipped);
  }
}
