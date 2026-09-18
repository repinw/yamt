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
  const new({required this.profile, required this.today});

  /// Calculator profile used to persist the goal.
  final CalorieCalculatorProfile profile;

  /// Current day. The goal always starts on this day.
  final DateTime today;
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

  /// Saves the calculated goal and bootstraps Burn Week from today.
  ///
  /// The start day itself is excluded from learning, because onboarding
  /// usually happens in the middle of a day that was not tracked.
  Future<bool> saveGoal(CalorieGoalOnboardingFinishRequest request) async {
    final goalStartDate = normalizeDiaryDay(request.today);
    final goalSaved = await _goalController.saveCalculatedGoal(
      request.profile,
      goalStartDate: goalStartDate,
      countGoalStartDayForLearning: false,
    );
    if (!goalSaved || !_isMounted()) {
      return false;
    }

    await _burnWeekController.bootstrapRunFrom(
      weekStartDate: goalStartDate,
      heartCreditKcal: 0,
    );
    return true;
  }
}
