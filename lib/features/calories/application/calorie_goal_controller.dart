import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_mutation_actions.dart';
import 'package:yamt/features/calories/application/calorie_goal_save_actions.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

part 'calorie_goal_controller.g.dart';

/// Result for saving a learned TDEE goal.
typedef LearnedTdeeGoalSaveResult = ({bool saved, bool goalChanged});

/// Defines calorie goal controller.
@riverpod
class CalorieGoalController extends _$CalorieGoalController {
  @override
  FutureOr<CalorieGoalSettings> build() {
    final repository = ref.watch(calorieSettingsRepositoryProvider);
    final initial = Completer<CalorieGoalSettings>();
    final subscription = repository.watchSettings().listen(
      (settings) {
        if (!initial.isCompleted) {
          initial.complete(settings);
          return;
        }
        if (ref.mounted) {
          state = AsyncData(settings);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initial.isCompleted) {
          initial.completeError(error, stackTrace);
          return;
        }
        if (ref.mounted) {
          state = AsyncError(error, stackTrace);
        }
      },
    );
    ref.onDispose(() {
      unawaited(subscription.cancel());
    });
    return initial.future;
  }

  /// Save calculated goal.
  Future<bool> saveCalculatedGoal(
    CalorieCalculatorProfile profile, {
    required DateTime goalStartDate,
    bool allowFutureGoalStart = false,
    bool? countGoalStartDayForLearning,
    bool archiveCurrentGoal = false,
  }) => _guarded(
    () => saveCalculatedCalorieGoal(
      controller: this,
      ref: ref,
      profile: profile,
      goalStartDate: goalStartDate,
      now: ref.read(clockProvider)(),
      allowFutureGoalStart: allowFutureGoalStart,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
      archiveCurrentGoal: archiveCurrentGoal,
    ),
  );

  /// Shift goal start.
  Future<bool> shiftGoalStart({required DateTime goalStartDate}) => _guarded(
    () => shiftCalorieGoalStart(
      controller: this,
      goalStartDate: goalStartDate,
      now: ref.read(clockProvider)(),
    ),
  );

  /// Persists target completion and reports whether it was newly reached.
  Future<bool> markGoalReachedIfNeeded({
    required DateTime day,
    required double weightKg,
  }) => _guarded(
    () => markCalorieGoalReachedIfNeeded(
      controller: this,
      day: day,
      weightKg: weightKg,
    ),
  );

  /// Records that the user explicitly answered the reached-goal prompt.
  Future<bool> markGoalReachedPromptHandled() => _guarded(
    () => markCalorieGoalReachedPromptHandled(
      controller: this,
      now: ref.read(clockProvider)(),
    ),
  );

  /// Set pending weekly check in.
  Future<bool> setPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) => _guarded(
    () => setPendingGoalWeeklyCheckIn(
      controller: this,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    ),
  );

  /// Dismiss pending weekly check in.
  Future<bool> dismissPendingWeeklyCheckIn({DateTime? dismissedAt}) => _guarded(
    () => dismissPendingGoalWeeklyCheckIn(
      controller: this,
      now: ref.read(clockProvider)(),
      dismissedAt: dismissedAt,
    ),
  );

  /// Set skipped intake day.
  Future<bool> setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) => _guarded(
    () => setCalorieSkippedIntakeDay(
      controller: this,
      logRepository: ref.read(calorieLogRepositoryProvider),
      day: day,
      isSkipped: isSkipped,
      now: ref.read(clockProvider)(),
    ),
  );

  /// Clear skipped intake day.
  Future<bool> clearSkippedIntakeDay(DateTime day) => _guarded(
    () => clearCalorieSkippedIntakeDay(
      controller: this,
      logRepository: ref.read(calorieLogRepositoryProvider),
      day: day,
      now: ref.read(clockProvider)(),
    ),
  );

  /// Mark weekly check-in snapshots dirty from a changed diary day.
  Future<bool> invalidateWeeklyCheckInSnapshotsFromDay(DateTime day) =>
      _guarded(
        () => invalidateGoalWeeklyCheckInSnapshots(
          controller: this,
          day: day,
          now: ref.read(clockProvider)(),
        ),
      );

  /// Save learned tdee goal and report whether goal data changed.
  Future<LearnedTdeeGoalSaveResult> saveLearnedTdeeGoalWithResult({
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required double? targetWeightKg,
    required DateTime goalStartDate,
    double? startWeightKg,
    DateTime? maintainUntil,
    bool? countGoalStartDayForLearning,
    bool archiveCurrentGoal = false,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
  }) => _guardedOr(
    (saved: false, goalChanged: false),
    () => saveLearnedTdeeCalorieGoal(
      controller: this,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      targetWeightKg: targetWeightKg,
      goalStartDate: goalStartDate,
      now: ref.read(clockProvider)(),
      startWeightKg: startWeightKg,
      maintainUntil: maintainUntil,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
      archiveCurrentGoal: archiveCurrentGoal,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
    ),
  );

  /// Save weekly check in goal.
  Future<bool> saveWeeklyCheckInGoal({
    required DateTime completedAt,
    required double dailyKcalGoal,
    required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  }) => _guarded(
    () => saveWeeklyCheckInCalorieGoal(
      controller: this,
      completedAt: completedAt,
      dailyKcalGoal: dailyKcalGoal,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
    ),
  );

  /// Toggle training day for a specific date.
  Future<bool> toggleTrainingDay(DateTime day) =>
      _guarded(() => toggleCalorieTrainingDay(controller: this, day: day));

  /// Set pause day for a specific date.
  Future<bool> setPauseDay({required DateTime day, required bool isPause}) =>
      _guarded(
        () => setCaloriePauseDay(controller: this, day: day, isPause: isPause),
      );

  /// Applies [change] to the current settings and persists the result.
  ///
  /// Reports `false` when the settings could not load or save.
  Future<bool> updateSettings(
    CalorieGoalSettings Function(CalorieGoalSettings settings) change,
  ) => _guarded(
    () async => await persistSettings(change(await currentSettings())),
  );

  /// Runs a goal action. The repository throws when the settings cannot load
  /// or save; the action then reports `false` instead.
  Future<bool> _guarded(Future<bool> Function() action) =>
      _guardedOr(false, action);

  Future<T> _guardedOr<T>(T failed, Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      log(
        'Calorie goal action failed.',
        name: 'CalorieGoalController',
        error: error,
        stackTrace: stackTrace,
      );
      return failed;
    }
  }

  /// Persists settings to storage and updates state.
  Future<bool> persistSettings(CalorieGoalSettings nextSettings) async {
    final previous = state;
    final optimistic = AsyncData(nextSettings);
    if (ref.mounted) {
      state = optimistic;
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    try {
      await repository.saveSettings(nextSettings);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist calorie goal settings.',
        name: 'CalorieGoalController',
        error: error,
        stackTrace: stackTrace,
      );
      _rollBack(previous, optimistic);
      return false;
    }
  }

  /// Undoes [optimistic] after a failed save, so an error stays an error and
  /// never turns into empty settings. Newer settings from the stream stay.
  /// Settings that were still loading load again, because setting a loading
  /// state by hand would leave the pending future open forever.
  void _rollBack(
    AsyncValue<CalorieGoalSettings> previous,
    AsyncData<CalorieGoalSettings> optimistic,
  ) {
    if (!ref.mounted || !identical(state, optimistic)) {
      return;
    }
    if (previous.hasError) {
      state = AsyncError(previous.error!, previous.stackTrace!);
    } else if (previous.hasValue) {
      state = AsyncData(previous.requireValue);
    } else {
      ref.invalidateSelf();
    }
  }

  /// Reads current settings from state or repository.
  Future<CalorieGoalSettings> currentSettings() async =>
      state.asData?.value ??
      await ref.read(calorieSettingsRepositoryProvider).readSettings();
}
