import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';

part 'calorie_onboarding_wizard_controller.g.dart';

/// Wizard steps for calorie-goal onboarding.
enum CalorieOnboardingStep {
  /// Welcome step.
  welcome,

  /// Personal info step.
  personalInfo,

  /// Activity step.
  activity,

  /// Goal weight step.
  goalWeight,

  /// Pace step.
  pace,

  /// Training days and calorie cycling step.
  trainingDays,

  /// Info step.
  info,

  /// Start-date step.
  startDate,

  /// Ready step.
  ready,
}

/// Immutable state for the calorie onboarding wizard.
@immutable
class CalorieOnboardingWizardState {
  /// Creates wizard state.
  const CalorieOnboardingWizardState({
    this.step = 0,
    this.showErrors = false,
    this.allowRouteExit = false,
    this.isSaving = false,
  });

  /// The list of steps in the onboarding wizard.
  static const List<CalorieOnboardingStep> steps = CalorieOnboardingStep.values;

  /// Current page index.
  final int step;

  /// Whether validation errors should be shown.
  final bool showErrors;

  /// Whether route exit is allowed.
  final bool allowRouteExit;

  /// Whether finish action is saving.
  final bool isSaving;

  /// Total wizard step count.
  int get totalSteps => steps.length;

  /// Current step.
  CalorieOnboardingStep get currentStep => steps[step];

  /// Whether wizard top/bottom chrome should be visible.
  bool get showsStepChrome => step > 0 && step < totalSteps - 1;

  /// Progress bar value.
  double get progress => step / (totalSteps - 1);

  /// Whether current step is valid.
  bool isCurrentStepValid(
    CalorieGoalCalculatorFormState formState, {
    required bool hasValidStartDateChoice,
  }) {
    return switch (currentStep) {
      CalorieOnboardingStep.personalInfo =>
        formState.sexError == null &&
            formState.ageError == null &&
            formState.heightError == null,
      CalorieOnboardingStep.goalWeight =>
        formState.weightError == null &&
            formState.targetWeightError == null &&
            formState.targetWeightKgText.isNotEmpty,
      CalorieOnboardingStep.startDate => hasValidStartDateChoice,
      _ => true,
    };
  }

  /// Copy with.
  CalorieOnboardingWizardState copyWith({
    int? step,
    bool? showErrors,
    bool? allowRouteExit,
    bool? isSaving,
  }) {
    return CalorieOnboardingWizardState(
      step: step ?? this.step,
      showErrors: showErrors ?? this.showErrors,
      allowRouteExit: allowRouteExit ?? this.allowRouteExit,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CalorieOnboardingWizardState &&
        other.step == step &&
        other.showErrors == showErrors &&
        other.allowRouteExit == allowRouteExit &&
        other.isSaving == isSaving;
  }

  @override
  int get hashCode => Object.hash(step, showErrors, allowRouteExit, isSaving);
}

/// State controller for the calorie onboarding wizard.
@riverpod
class CalorieOnboardingWizardController
    extends _$CalorieOnboardingWizardController {
  @override
  CalorieOnboardingWizardState build() {
    return const CalorieOnboardingWizardState();
  }

  /// Move to next page. Returns target page index when changed.
  int? next(
    CalorieGoalCalculatorFormState formState, {
    required bool hasValidStartDateChoice,
  }) {
    if (state.step >= state.totalSteps - 1) {
      return null;
    }
    if (!state.isCurrentStepValid(
      formState,
      hasValidStartDateChoice: hasValidStartDateChoice,
    )) {
      state = state.copyWith(showErrors: true);
      return null;
    }

    var nextStep = state.step + 1;
    if (nextStep < state.totalSteps &&
        CalorieOnboardingWizardState.steps[nextStep] ==
            CalorieOnboardingStep.pace &&
        formState.goalMode == CalorieGoalMode.maintain) {
      nextStep++;
    }

    state = state.copyWith(step: nextStep, showErrors: false);
    return state.step;
  }

  /// Move to previous page. Returns target page index when changed.
  int? back(CalorieGoalCalculatorFormState formState) {
    if (state.step <= 0) {
      return null;
    }

    var prevStep = state.step - 1;
    if (prevStep >= 0 &&
        CalorieOnboardingWizardState.steps[prevStep] ==
            CalorieOnboardingStep.pace &&
        formState.goalMode == CalorieGoalMode.maintain) {
      prevStep--;
    }

    state = state.copyWith(step: prevStep);
    return state.step;
  }

  /// Hide currently visible validation errors.
  void clearErrors() {
    if (!state.showErrors) {
      return;
    }
    state = state.copyWith(showErrors: false);
  }

  /// Start saving.
  void startSaving() {
    state = state.copyWith(isSaving: true);
  }

  /// Stop saving after a failed save.
  void stopSavingAfterFailure() {
    state = state.copyWith(isSaving: false);
  }

  /// Allow route exit after successful save.
  void markRouteExitAllowed() {
    state = state.copyWith(allowRouteExit: true);
  }
}
