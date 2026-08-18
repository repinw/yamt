import 'package:flutter/material.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_start_date_controller.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_0_welcome.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_1_personal_info.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_2_activity.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_3_goal_weight.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_4_pace.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_5_info.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_6_start_date.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_7_ready.dart';

/// Page list for the calorie onboarding wizard.
class CalorieOnboardingStepPages extends StatelessWidget {
  /// Creates onboarding step pages.
  const CalorieOnboardingStepPages({
    required this.pageController,
    required this.formState,
    required this.formNotifier,
    required this.showErrors,
    required this.startDateController,
    required this.isSaving,
    required this.onNext,
    required this.onStartNowChanged,
    required this.onTodayModeChanged,
    required this.onCatchUpEstimateChanged,
    required this.onFutureGoalStartChangeRequested,
    required this.onFinish,
    this.onLogin,
    super.key,
  });

  /// Page controller used by the coordinator widget.
  final PageController pageController;

  /// Current calculator form state.
  final CalorieGoalCalculatorFormState formState;

  /// Calculator form notifier.
  final CalorieGoalCalculatorFormController formNotifier;

  /// Whether validation errors should be shown.
  final bool showErrors;

  /// Start-date choice state controller.
  final CalorieOnboardingStartDateController startDateController;

  /// Whether the finish action is currently saving.
  final bool isSaving;

  /// Advances the wizard.
  final VoidCallback onNext;

  /// Called when existing user wants to log in from welcome step.
  final VoidCallback? onLogin;

  /// Updates the start-now choice.
  final ValueChanged<bool> onStartNowChanged;

  /// Updates today's tracking mode.
  final ValueChanged<CalorieGoalOnboardingTodayTracking> onTodayModeChanged;

  /// Updates the catch-up estimate.
  final ValueChanged<CalorieGoalOnboardingCatchUpEstimate>
  onCatchUpEstimateChanged;

  /// Opens the future start-date picker.
  final VoidCallback onFutureGoalStartChangeRequested;

  /// Finishes onboarding.
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Step0Welcome(
          onNext: onNext,
          onLogin: onLogin,
        ),
        Step1PersonalInfo(
          state: formState,
          notifier: formNotifier,
          showErrors: showErrors,
        ),
        Step2Activity(
          state: formState,
          notifier: formNotifier,
        ),
        Step3GoalWeight(
          state: formState,
          notifier: formNotifier,
          showErrors: showErrors,
        ),
        Step4Pace(
          state: formState,
          notifier: formNotifier,
        ),
        const Step5Info(),
        Step6StartDate(
          startNow: startDateController.startNowChoice,
          todayMode: startDateController.todayTrackingChoice,
          catchUpEstimate: startDateController.catchUpEstimate,
          futureGoalStartDate: startDateController.futureGoalStartDate,
          showErrors: showErrors,
          onStartNowChanged: onStartNowChanged,
          onTodayModeChanged: onTodayModeChanged,
          onCatchUpEstimateChanged: onCatchUpEstimateChanged,
          onFutureGoalStartChangeRequested: onFutureGoalStartChangeRequested,
        ),
        Step7Ready(
          isSaving: isSaving,
          calculation: formState.calculation,
          onFinish: onFinish,
        ),
      ],
    );
  }
}
