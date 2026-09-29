import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_snapshot_rules.dart';
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

  Future<T> _keepAliveDuring<T>(
    Future<T> Function(CalorieGoalController goalController) action,
  ) async {
    final link = ref.keepAlive();
    final goalSubscription = ref.listen(
      calorieGoalControllerProvider,
      (previous, next) {},
    );
    try {
      return await action(ref.read(calorieGoalControllerProvider.notifier));
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
      final settings = await ref
          .read(calorieSettingsRepositoryProvider)
          .readSettings();
      if (!ref.mounted) {
        return false;
      }
      final currentPending = settings.pendingWeeklyCheckIn;
      if (currentPending != null &&
          currentPending.windowKey == pendingWeeklyCheckIn.windowKey &&
          currentPending.dismissedAt == pendingWeeklyCheckIn.dismissedAt) {
        return true;
      }
      return await goalController.setPendingWeeklyCheckIn(pendingWeeklyCheckIn);
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

  /// Sync learned TDEE cache for a ready weekly check in.
  Future<bool> syncLearnedTdeeCache(CalorieWeeklyCheckInData checkInData) {
    return _keepAliveDuring((goalController) async {
      final pendingWeeklyCheckIn = checkInData.pendingWeeklyCheckIn;
      final cacheWeeklyCheckIn =
          checkInData.cacheWeeklyCheckIn ?? pendingWeeklyCheckIn;
      final calculation = checkInData.calculation;
      if (cacheWeeklyCheckIn == null ||
          calculation == null ||
          checkInData.isBlocked) {
        return true;
      }

      if (pendingWeeklyCheckIn != null &&
          pendingWeeklyCheckIn.windowKey == cacheWeeklyCheckIn.windowKey) {
        final synced = await syncPendingWeeklyCheckIn(pendingWeeklyCheckIn);
        if (!ref.mounted) {
          return false;
        }
        if (!synced) {
          return false;
        }
      }

      final weeklyCheckInSnapshot = weeklyCheckInSnapshotFor(
        weeklyCheckIn: cacheWeeklyCheckIn,
        calculation: calculation,
        lowConfidence: checkInData.lowConfidence,
        inputHash: checkInData.inputHash,
        macroWeightKg: checkInData.macroWeightKg,
      );
      final settings = await ref
          .read(calorieSettingsRepositoryProvider)
          .readSettings();
      if (!ref.mounted) {
        return false;
      }
      if (hasRejectedWeeklyCheckInSnapshot(
        settings: settings,
        weeklyCheckIn: cacheWeeklyCheckIn,
      )) {
        return true;
      }
      if (hasMatchingWeeklyCheckInSnapshot(
        settings: settings,
        dailyKcalGoal: calculation.newGoalKcal,
        weeklyCheckInSnapshot: weeklyCheckInSnapshot,
      )) {
        return true;
      }

      return await goalController.saveWeeklyCheckInGoal(
        completedAt: cacheWeeklyCheckIn.dueDate,
        dailyKcalGoal: calculation.newGoalKcal,
        weeklyCheckInSnapshot: weeklyCheckInSnapshot,
      );
    });
  }

  /// Syncs the pending check-in before the user's decision is applied.
  ///
  /// Returns `false` when there is nothing to decide or the sync failed.
  Future<bool> _syncPendingBeforeDecision(
    CalorieWeeklyCheckInData checkInData,
  ) async {
    final pendingWeeklyCheckIn = checkInData.pendingWeeklyCheckIn;
    final calculation = checkInData.calculation;
    if (pendingWeeklyCheckIn == null ||
        calculation == null ||
        checkInData.isBlocked) {
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
    return true;
  }

  /// Apply weekly check in.
  Future<bool> applyWeeklyCheckIn(CalorieWeeklyCheckInData checkInData) {
    return _keepAliveDuring((goalController) async {
      if (!await _syncPendingBeforeDecision(checkInData)) {
        return false;
      }

      final savedSnapshot = await syncLearnedTdeeCache(checkInData);

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

      final saved = await goalController.clearPendingWeeklyCheckIn();

      if (!ref.mounted) {
        return saved;
      }
      state = const AsyncData(null);
      return saved;
    });
  }

  /// Reject weekly check in.
  Future<bool> rejectWeeklyCheckIn(CalorieWeeklyCheckInData checkInData) {
    return _keepAliveDuring((goalController) async {
      if (!await _syncPendingBeforeDecision(checkInData)) {
        return false;
      }
      final pendingWeeklyCheckIn = checkInData.pendingWeeklyCheckIn!;
      final calculation = checkInData.calculation!;

      final settings = await ref
          .read(calorieSettingsRepositoryProvider)
          .readSettings();
      if (!ref.mounted) {
        return false;
      }

      final previousGoalKcal = goalKcalBeforeWeeklyCheckIn(
        settings: settings,
        checkInWindowStartDate: pendingWeeklyCheckIn.windowStartDate,
      );

      final rejectedSnapshot = weeklyCheckInSnapshotFor(
        weeklyCheckIn: pendingWeeklyCheckIn,
        calculation: calculation,
        lowConfidence: checkInData.lowConfidence,
        inputHash: checkInData.inputHash,
        macroWeightKg: checkInData.macroWeightKg,
      ).copyWith(isRejected: true);

      final savedGoal = await goalController.saveWeeklyCheckInGoal(
        completedAt: pendingWeeklyCheckIn.dueDate,
        dailyKcalGoal: previousGoalKcal,
        weeklyCheckInSnapshot: rejectedSnapshot,
      );

      if (!ref.mounted) {
        return savedGoal;
      }
      if (!savedGoal) {
        state = AsyncError(
          StateError('Failed to persist rejected weekly check-in.'),
          StackTrace.empty,
        );
        return false;
      }

      final saved = await goalController.clearPendingWeeklyCheckIn();

      if (!ref.mounted) {
        return saved;
      }
      state = const AsyncData(null);
      return saved;
    });
  }
}
