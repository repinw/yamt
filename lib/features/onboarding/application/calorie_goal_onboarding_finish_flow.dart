import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_onboarding_finish_flow.g.dart';

/// Onboarding-owned flow for saving the initial calorie goal.
@riverpod
CalorieGoalOnboardingFinishFlow calorieGoalOnboardingFinishFlow(Ref ref) {
  return CalorieGoalOnboardingFinishFlow(
    goalController: ref.watch(calorieGoalControllerProvider.notifier),
    burnWeekController: ref.read(burnWeekRunControllerProvider.notifier),
    isMounted: () => ref.mounted,
  );
}

/// Inputs needed to finish calorie-goal onboarding.
class CalorieGoalOnboardingFinishRequest {
  /// Creates finish request.
  const new({
    required this.profile,
    required this.today,
    required this.startDate,
  });

  /// Calculator profile used to persist the goal.
  final CalorieCalculatorProfile profile;

  /// Current day.
  final DateTime today;

  /// Day the first tracked week starts: today or a later day.
  final DateTime startDate;
}

/// Saves calorie onboarding and places the user into Burn Week.
class CalorieGoalOnboardingFinishFlow {
  /// Creates flow.
  const new({
    required this._goalController,
    required this._burnWeekController,
    required this._isMounted,
  });

  final CalorieGoalController _goalController;
  final BurnWeekRunController _burnWeekController;
  final bool Function() _isMounted;

  /// Saves the calculated goal counting from the chosen start day.
  ///
  /// The start day always counts for learning: the user chose it knowing that
  /// the whole day has to be tracked. A start today bootstraps Burn Week right
  /// away. A later start leaves the days before it as practice days, and Burn
  /// Week live sync starts the run on the start day.
  Future<bool> saveGoal(CalorieGoalOnboardingFinishRequest request) async {
    final today = normalizeDiaryDay(request.today);
    final startDate = normalizeDiaryDay(request.startDate);
    final startsLater = startDate.isAfter(today);
    final goalSaved = await _goalController.saveCalculatedGoal(
      request.profile,
      goalStartDate: startDate,
      allowFutureGoalStart: startsLater,
      countGoalStartDayForLearning: true,
    );
    if (!goalSaved || !_isMounted()) {
      return false;
    }
    if (startsLater) {
      return true;
    }

    await _burnWeekController.bootstrapRunFrom(
      weekStartDate: startDate,
      heartCreditKcal: 0,
    );
    return true;
  }
}
