import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/onboarding/application/calorie_goal_onboarding_catch_up_placeholder_writer.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';

part 'calorie_goal_onboarding_finish_flow.g.dart';

/// Onboarding-owned flow for saving the initial calorie goal.
@riverpod
CalorieGoalOnboardingFinishFlow calorieGoalOnboardingFinishFlow(Ref ref) {
  final goalController = ref.watch(calorieGoalControllerProvider.notifier);
  return CalorieGoalOnboardingFinishFlow(
    readSettings: () => ref.read(calorieGoalControllerProvider.future),
    goalController: goalController,
    burnWeekController: ref.read(burnWeekRunControllerProvider.notifier),
    catchUpPlaceholderWriter: CalorieGoalOnboardingCatchUpPlaceholderWriter(
      logRepository: ref.read(calorieLogRepositoryProvider),
      isMounted: () => ref.mounted,
    ),
    isMounted: () => ref.mounted,
  );
}

/// Inputs needed to finish calorie-goal onboarding.
class CalorieGoalOnboardingFinishRequest {
  /// Creates finish request.
  const CalorieGoalOnboardingFinishRequest({
    required this.profile,
    required this.dailyGoalKcal,
    required this.goalStartDate,
    required this.countGoalStartDayForLearning,
    required this.catchUpEstimate,
    required this.placeholderName,
    this.now,
  });

  /// Calculator profile used to persist the goal.
  final CalorieCalculatorProfile profile;

  /// Daily calorie target to use for same-day catch-up placement.
  final double dailyGoalKcal;

  /// Date on which the goal should begin.
  final DateTime goalStartDate;

  /// Whether the goal-start day counts for learning.
  final bool? countGoalStartDayForLearning;

  /// Optional same-day catch-up estimate.
  final CalorieGoalOnboardingCatchUpEstimate? catchUpEstimate;

  /// Localized name for catch-up placeholder diary entries.
  final String placeholderName;

  /// Optional clock override for deterministic tests.
  final DateTime? now;
}

/// Saves calorie onboarding and places the user into Burn Week.
class CalorieGoalOnboardingFinishFlow {
  /// Creates flow.
  const CalorieGoalOnboardingFinishFlow({
    required Future<CalorieGoalSettings> Function() readSettings,
    required CalorieGoalController goalController,
    required BurnWeekRunController burnWeekController,
    required CalorieGoalOnboardingCatchUpPlaceholderWriter
    catchUpPlaceholderWriter,
    required bool Function() isMounted,
  }) : _readSettings = readSettings,
       _goalController = goalController,
       _burnWeekController = burnWeekController,
       _catchUpPlaceholderWriter = catchUpPlaceholderWriter,
       _isMounted = isMounted;

  final Future<CalorieGoalSettings> Function() _readSettings;
  final CalorieGoalController _goalController;
  final BurnWeekRunController _burnWeekController;
  final CalorieGoalOnboardingCatchUpPlaceholderWriter _catchUpPlaceholderWriter;
  final bool Function() _isMounted;

  /// Save calculated goal and bootstrap Burn Week for onboarding.
  Future<bool> saveGoal(CalorieGoalOnboardingFinishRequest request) async {
    final referenceNow = request.now ?? DateTime.now();
    final existingSettings = await _readSettings();
    if (!_isMounted()) {
      return false;
    }
    const runWeekNumber = burnWeekLearningRunWeekNumber;
    final goalSaved = await _goalController.saveCalculatedGoal(
      request.profile,
      goalStartDate: request.goalStartDate,
      allowFutureGoalStart: true,
      countGoalStartDayForLearning: request.countGoalStartDayForLearning,
    );
    if (!goalSaved || !_isMounted()) {
      return false;
    }
    return _applyBurnWeekStart(
      goalStartDate: request.goalStartDate,
      now: referenceNow,
      dailyGoalKcal: request.dailyGoalKcal,
      runWeekNumber: runWeekNumber,
      scheduleFutureStart: existingSettings.hasLearnedTdee,
      catchUpEstimate: request.catchUpEstimate,
      placeholderName: request.placeholderName,
    );
  }

  Future<bool> _applyBurnWeekStart({
    required DateTime goalStartDate,
    required DateTime now,
    required double dailyGoalKcal,
    required int runWeekNumber,
    required bool scheduleFutureStart,
    required CalorieGoalOnboardingCatchUpEstimate? catchUpEstimate,
    required String placeholderName,
  }) async {
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    final normalizedToday = normalizeDiaryDay(now);
    if (normalizedGoalStartDate.isAfter(normalizedToday)) {
      if (scheduleFutureStart) {
        await _burnWeekController.restartRunFrom(
          weekStartDate: normalizedGoalStartDate,
          runWeekNumber: runWeekNumber,
        );
        return true;
      }
      await _burnWeekController.resetRun();
      return true;
    }
    if (catchUpEstimate == null) {
      await _burnWeekController.restartRunFrom(
        weekStartDate: normalizedGoalStartDate,
        runWeekNumber: runWeekNumber,
      );
      return true;
    }

    final placeholdersSaved = await _catchUpPlaceholderWriter.writePlaceholders(
      now: now,
      dailyGoalKcal: dailyGoalKcal,
      estimate: catchUpEstimate,
      placeholderName: placeholderName,
    );
    if (!placeholdersSaved) {
      return false;
    }

    await _burnWeekController.bootstrapRunFrom(
      weekStartDate: normalizedGoalStartDate,
      heartCreditKcal: 0,
      runWeekNumber: runWeekNumber,
    );
    return true;
  }
}
