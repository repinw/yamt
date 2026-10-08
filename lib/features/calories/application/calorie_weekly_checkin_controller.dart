import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_snapshot_rules.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

part 'calorie_weekly_checkin_controller.g.dart';

/// Defines calorie weekly check in controller.
///
/// Diary dialog callbacks capture this notifier, so every action keeps this
/// controller and the goal controller alive until it ends.
@riverpod
class CalorieWeeklyCheckInController extends _$CalorieWeeklyCheckInController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  /// Runs [action] and reports a failed settings read or write as `false`
  /// with an [AsyncError] state.
  Future<bool> _keepAliveDuring(
    Future<bool> Function(CalorieGoalController goalController) action,
  ) async {
    final link = ref.keepAlive();
    final goalSubscription = ref.listen(
      calorieGoalControllerProvider,
      (previous, next) {},
    );
    try {
      return await action(ref.read(calorieGoalControllerProvider.notifier));
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      return false;
    } finally {
      goalSubscription.close();
      link.close();
    }
  }

  /// Sync pending weekly check in.
  Future<bool> syncPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) {
    return _keepAliveDuring((goalController) async {
      final settings = await goalController.currentSettings();
      if (!ref.mounted) {
        return false;
      }
      return !pendingWeeklyCheckInNeedsSave(
            settings: settings,
            pendingWeeklyCheckIn: pendingWeeklyCheckIn,
          ) ||
          await goalController.setPendingWeeklyCheckIn(pendingWeeklyCheckIn);
    });
  }

  /// Clears dismissal for a pending weekly check in.
  Future<bool> showPendingWeeklyCheckInAgain(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) {
    return _keepAliveDuring((goalController) async {
      state = const AsyncLoading();
      final restoredPending = pendingWeeklyCheckIn.copyWith(dismissedAt: null);
      final saved = await goalController.setPendingWeeklyCheckIn(
        restoredPending,
      );
      if (!ref.mounted) {
        return saved;
      }
      state = saved
          ? const AsyncData(null)
          : AsyncError(
              StateError('Failed to reopen pending weekly check-in.'),
              StackTrace.empty,
            );
      return saved;
    });
  }

  /// Persists a ready pending check-in and saves what
  /// [CalorieWeeklyCheckInData.snapshotToSaveUndecided] names.
  Future<bool> syncLearnedTdeeCache(CalorieWeeklyCheckInData checkInData) {
    return _keepAliveDuring((goalController) async {
      final pendingWeeklyCheckIn = checkInData.pendingWeeklyCheckIn;
      final synced =
          !checkInData.isReady ||
          await syncPendingWeeklyCheckIn(pendingWeeklyCheckIn!);
      if (!synced || !ref.mounted) {
        return false;
      }
      final settings = await goalController.currentSettings();
      if (!ref.mounted) {
        return false;
      }
      final save = checkInData.snapshotToSaveUndecided(
        settings: settings,
        latestDueWindow: resolveLatestCompletedCalorieWeeklyCheckIn(
          settings: settings,
          today: normalizeDiaryDay(ref.read(clockProvider)()),
        ),
      );
      return save == null ||
          await _saveLearnedTdeeSnapshot(
            goalController,
            save.window,
            save.snapshot,
          );
    });
  }

  /// Saves the goal of [weeklyCheckInSnapshot], unless the history already
  /// holds it.
  Future<bool> _saveLearnedTdeeSnapshot(
    CalorieGoalController goalController,
    PendingCalorieGoalWeeklyCheckIn weeklyCheckIn,
    CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  ) async {
    final dailyKcalGoal = weeklyCheckInSnapshot.baseGoalKcal;
    final settings = await goalController.currentSettings();
    if (!ref.mounted) {
      return false;
    }
    return hasMatchingWeeklyCheckInSnapshot(
          settings: settings,
          dailyKcalGoal: dailyKcalGoal,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        ) ||
        await goalController.saveWeeklyCheckInGoal(
          completedAt: weeklyCheckIn.dueDate,
          dailyKcalGoal: dailyKcalGoal,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        );
  }

  /// Apply weekly check in, with the [training] of the next run.
  Future<bool> applyWeeklyCheckIn(
    CalorieWeeklyCheckInData checkInData, {
    CalorieRunTrainingChoice? training,
  }) => _decide(checkInData, accept: true, training: training);

  /// Reject weekly check in, with the [training] of the next run.
  Future<bool> rejectWeeklyCheckIn(
    CalorieWeeklyCheckInData checkInData, {
    CalorieRunTrainingChoice? training,
  }) => _decide(checkInData, accept: false, training: training);

  /// Saves the whole decision at once, so a failure leaves nothing half
  /// applied and the check-in open for another try.
  Future<bool> _decide(
    CalorieWeeklyCheckInData checkInData, {
    required bool accept,
    required CalorieRunTrainingChoice? training,
  }) {
    return _keepAliveDuring((goalController) async {
      final pending = checkInData.pendingWeeklyCheckIn;
      final calculation = checkInData.calculation;
      if (pending == null || calculation == null || checkInData.isBlocked) {
        return false;
      }
      state = const AsyncLoading();
      final settings = await goalController.currentSettings();
      if (!ref.mounted) {
        return false;
      }
      final next = decideWeeklyCheckIn(
        settings: settings,
        pending: pending,
        snapshot: checkInData.snapshotFor(pending, calculation),
        accept: accept,
        today: ref.read(clockProvider)(),
        training: training,
      );
      final saved = next != null && await goalController.persistSettings(next);
      if (!ref.mounted) {
        return saved;
      }
      state = saved
          ? const AsyncData(null)
          : AsyncError(
              StateError('Failed to save the weekly check-in decision.'),
              StackTrace.empty,
            );
      return saved;
    });
  }
}
