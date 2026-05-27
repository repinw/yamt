import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';

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

  /// Clears dismissal for a pending weekly check in.
  Future<bool> showPendingWeeklyCheckInAgain(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) async {
    state = const AsyncLoading();
    final restoredPending = pendingWeeklyCheckIn.copyWith(dismissedAt: null);
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .setPendingWeeklyCheckIn(restoredPending);
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
  }

  /// Sync learned TDEE cache for a ready weekly check in.
  Future<bool> syncLearnedTdeeCache(
    CalorieWeeklyCheckInData checkInData,
  ) async {
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

    final weeklyCheckInSnapshot = _weeklyCheckInSnapshot(
      weeklyCheckIn: cacheWeeklyCheckIn,
      calculation: calculation,
      lowConfidence: checkInData.lowConfidence,
      inputHash: checkInData.inputHash,
    );
    final settings = await ref.read(calorieGoalControllerProvider.future);
    if (!ref.mounted) {
      return false;
    }
    if (_hasMatchingWeeklyCheckInSnapshot(
      settings: settings,
      dailyKcalGoal: calculation.newGoalKcal,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
    )) {
      return true;
    }

    return ref
        .read(calorieGoalControllerProvider.notifier)
        .saveWeeklyCheckInGoal(
          completedAt: cacheWeeklyCheckIn.dueDate,
          dailyKcalGoal: calculation.newGoalKcal,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        );
  }

  /// Apply weekly check in.
  Future<bool> applyWeeklyCheckIn(
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

    final goalController = ref.read(calorieGoalControllerProvider.notifier);
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

    final saved = await goalController.dismissPendingWeeklyCheckIn();

    if (saved && ref.mounted) {
      await ref
          .read(burnWeekRunControllerProvider.notifier)
          .refillHeartsForWeeklyCheckIn();
    }
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

bool _hasMatchingWeeklyCheckInSnapshot({
  required CalorieGoalSettings settings,
  required double dailyKcalGoal,
  required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
}) {
  var hasSameWindowSnapshot = false;
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (!_sameWeeklyCheckInSnapshot(snapshot, weeklyCheckInSnapshot)) {
      continue;
    }
    hasSameWindowSnapshot = true;
    final goalMatches =
        !entry.isWeeklyCheckIn ||
        _sameDouble(entry.dailyKcalGoal, dailyKcalGoal);
    final matches =
        goalMatches &&
        snapshot.lowConfidence == weeklyCheckInSnapshot.lowConfidence &&
        _sameDouble(
          snapshot.trendWeightChangePerDay,
          weeklyCheckInSnapshot.trendWeightChangePerDay,
        ) &&
        _sameDouble(
          snapshot.measuredTotalTdeeKcal,
          weeklyCheckInSnapshot.measuredTotalTdeeKcal,
        ) &&
        _sameDouble(
          snapshot.measuredBaseTdeeKcal,
          weeklyCheckInSnapshot.measuredBaseTdeeKcal,
        ) &&
        _sameDouble(
          snapshot.calculatedBaseTdeeKcal,
          weeklyCheckInSnapshot.calculatedBaseTdeeKcal,
        ) &&
        _sameDouble(
          snapshot.averageCreditedActivityKcal,
          weeklyCheckInSnapshot.averageCreditedActivityKcal,
        ) &&
        _sameDouble(
          snapshot.baseGoalKcal,
          weeklyCheckInSnapshot.baseGoalKcal,
        ) &&
        snapshot.inputHash == weeklyCheckInSnapshot.inputHash &&
        snapshot.invalidatedAt == weeklyCheckInSnapshot.invalidatedAt;
    if (!matches) {
      return false;
    }
  }
  return hasSameWindowSnapshot;
}

bool _sameWeeklyCheckInSnapshot(
  CalorieGoalWeeklyCheckInSnapshot left,
  CalorieGoalWeeklyCheckInSnapshot right,
) {
  return isSameDiaryDay(left.windowStartDate, right.windowStartDate) &&
      isSameDiaryDay(left.windowEndDate, right.windowEndDate);
}

bool _sameDouble(double? left, double? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return (left - right).abs() < 0.0001;
}

CalorieGoalWeeklyCheckInSnapshot _weeklyCheckInSnapshot({
  required PendingCalorieGoalWeeklyCheckIn weeklyCheckIn,
  required CalorieWeeklyCheckInCalculation calculation,
  required bool lowConfidence,
  required String? inputHash,
}) {
  return CalorieGoalWeeklyCheckInSnapshot(
    windowStartDate: weeklyCheckIn.windowStartDate,
    windowEndDate: weeklyCheckIn.windowEndDate,
    trendWeightChangePerDay: calculation.trendWeightChangePerDay,
    measuredTotalTdeeKcal: calculation.measuredTotalTdeeKcal,
    measuredBaseTdeeKcal: calculation.measuredBaseTdeeKcal,
    calculatedBaseTdeeKcal: calculation.calculatedBaseTdeeKcal,
    averageCreditedActivityKcal: calculation.averageCreditedActivityKcal,
    baseGoalKcal: calculation.newBaseGoalKcal,
    lowConfidence: lowConfidence,
    inputHash: inputHash,
  );
}
