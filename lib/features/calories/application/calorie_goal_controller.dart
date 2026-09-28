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

  /// Set goal.
  Future<bool> setGoal(double dailyKcalGoal) => setManualCalorieGoal(
    controller: this,
    dailyKcalGoal: dailyKcalGoal,
    now: ref.read(clockProvider)(),
  );

  /// Save calculated goal.
  Future<bool> saveCalculatedGoal(
    CalorieCalculatorProfile profile, {
    required DateTime goalStartDate,
    bool allowFutureGoalStart = false,
    bool? countGoalStartDayForLearning,
    bool archiveCurrentGoal = false,
  }) => saveCalculatedCalorieGoal(
    controller: this,
    ref: ref,
    profile: profile,
    goalStartDate: goalStartDate,
    now: ref.read(clockProvider)(),
    allowFutureGoalStart: allowFutureGoalStart,
    countGoalStartDayForLearning: countGoalStartDayForLearning,
    archiveCurrentGoal: archiveCurrentGoal,
  );

  /// Shift goal start.
  Future<bool> shiftGoalStart({required DateTime goalStartDate}) =>
      shiftCalorieGoalStart(
        controller: this,
        goalStartDate: goalStartDate,
        now: ref.read(clockProvider)(),
      );

  /// Clear goal.
  Future<bool> clearGoal() =>
      clearCalorieGoal(controller: this, now: ref.read(clockProvider)());

  /// Persists target completion and reports whether it was newly reached.
  Future<bool> markGoalReachedIfNeeded({
    required DateTime day,
    required double weightKg,
  }) => markCalorieGoalReachedIfNeeded(
    controller: this,
    day: day,
    weightKg: weightKg,
  );

  /// Records that the user explicitly answered the reached-goal prompt.
  Future<bool> markGoalReachedPromptHandled() =>
      markCalorieGoalReachedPromptHandled(
        controller: this,
        now: ref.read(clockProvider)(),
      );

  /// Set pending weekly check in.
  Future<bool> setPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) => setPendingGoalWeeklyCheckIn(
    controller: this,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
  );

  /// Dismiss pending weekly check in.
  Future<bool> dismissPendingWeeklyCheckIn({DateTime? dismissedAt}) =>
      dismissPendingGoalWeeklyCheckIn(
        controller: this,
        now: ref.read(clockProvider)(),
        dismissedAt: dismissedAt,
      );

  /// Clear pending weekly check in.
  Future<bool> clearPendingWeeklyCheckIn() =>
      clearPendingGoalWeeklyCheckIn(controller: this);

  /// Set skipped intake day.
  Future<bool> setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) => setCalorieSkippedIntakeDay(
    controller: this,
    logRepository: ref.read(calorieLogRepositoryProvider),
    day: day,
    isSkipped: isSkipped,
    now: ref.read(clockProvider)(),
  );

  /// Clear skipped intake day.
  Future<bool> clearSkippedIntakeDay(DateTime day) =>
      clearCalorieSkippedIntakeDay(
        controller: this,
        logRepository: ref.read(calorieLogRepositoryProvider),
        day: day,
        now: ref.read(clockProvider)(),
      );

  /// Mark weekly check-in snapshots dirty from a changed diary day.
  Future<bool> invalidateWeeklyCheckInSnapshotsFromDay(DateTime day) =>
      invalidateGoalWeeklyCheckInSnapshots(
        controller: this,
        day: day,
        now: ref.read(clockProvider)(),
      );

  /// Save learned tdee goal.
  Future<bool> saveLearnedTdeeGoal({
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
  }) async => (await saveLearnedTdeeGoalWithResult(
    goalMode: goalMode,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    targetWeightKg: targetWeightKg,
    goalStartDate: goalStartDate,
    startWeightKg: startWeightKg,
    maintainUntil: maintainUntil,
    countGoalStartDayForLearning: countGoalStartDayForLearning,
    archiveCurrentGoal: archiveCurrentGoal,
    trainingWeekdays: trainingWeekdays,
    trainingDayKcalOffset: trainingDayKcalOffset,
  )).saved;

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
  }) => saveLearnedTdeeCalorieGoal(
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
  );

  /// Save weekly check in goal.
  Future<bool> saveWeeklyCheckInGoal({
    required DateTime completedAt,
    required double dailyKcalGoal,
    required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  }) => saveWeeklyCheckInCalorieGoal(
    controller: this,
    completedAt: completedAt,
    dailyKcalGoal: dailyKcalGoal,
    weeklyCheckInSnapshot: weeklyCheckInSnapshot,
  );

  /// Toggle training day for a specific date.
  Future<bool> toggleTrainingDay(DateTime day) =>
      toggleCalorieTrainingDay(controller: this, day: day);

  /// Update weekly training days and kcal offset.
  Future<bool> updateTrainingSchedule({
    required List<int> trainingWeekdays,
    required double trainingDayKcalOffset,
  }) => updateCalorieTrainingSchedule(
    controller: this,
    trainingWeekdays: trainingWeekdays,
    trainingDayKcalOffset: trainingDayKcalOffset,
  );

  /// Set pause day for a specific date.
  Future<bool> setPauseDay({required DateTime day, required bool isPause}) =>
      setCaloriePauseDay(controller: this, day: day, isPause: isPause);

  /// Persists settings to storage and updates state.
  Future<bool> persistSettings(CalorieGoalSettings nextSettings) async {
    final previous = state.asData?.value ?? const CalorieGoalSettings.empty();
    if (ref.mounted) {
      state = AsyncData(nextSettings);
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    try {
      final saved = await repository.saveSettings(nextSettings);
      if (!saved && ref.mounted) {
        state = AsyncData(previous);
      }
      return saved;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist calorie goal settings.',
        name: 'CalorieGoalController',
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previous);
      }
      return false;
    }
  }

  /// Reads current settings from state or repository.
  Future<CalorieGoalSettings> currentSettings() async =>
      state.asData?.value ??
      await ref.read(calorieSettingsRepositoryProvider).readSettings();
}
