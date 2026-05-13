import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';

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

  /// Info step.
  info,

  /// Start-date step.
  startDate,

  /// Ready step.
  ready,
}

/// State controller for the calorie onboarding wizard.
class CalorieOnboardingWizardController extends ChangeNotifier {
  /// Creates controller.
  CalorieOnboardingWizardController();

  static const List<CalorieOnboardingStep> _steps =
      CalorieOnboardingStep.values;

  int _step = 0;
  bool _showErrors = false;
  bool _allowRouteExit = false;
  bool _isSaving = false;

  /// Current page index.
  int get step => _step;

  /// Total wizard step count.
  int get totalSteps => _steps.length;

  /// Current step.
  CalorieOnboardingStep get currentStep => _steps[_step];

  /// Whether validation errors should be shown.
  bool get showErrors => _showErrors;

  /// Whether route exit is allowed.
  bool get allowRouteExit => _allowRouteExit;

  /// Whether finish action is saving.
  bool get isSaving => _isSaving;

  /// Whether wizard top/bottom chrome should be visible.
  bool get showsStepChrome => _step > 0 && _step < totalSteps - 1;

  /// Progress bar value.
  double get progress => _step / (totalSteps - 1);

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

  /// Move to next page. Returns target page when page changed.
  int? next(
    CalorieGoalCalculatorFormState formState, {
    required bool hasValidStartDateChoice,
  }) {
    if (_step >= totalSteps - 1) {
      return null;
    }
    if (!isCurrentStepValid(
      formState,
      hasValidStartDateChoice: hasValidStartDateChoice,
    )) {
      _showErrors = true;
      notifyListeners();
      return null;
    }

    _step++;
    if (currentStep == CalorieOnboardingStep.pace &&
        formState.goalMode == CalorieGoalMode.maintain) {
      _step++;
    }
    _showErrors = false;
    notifyListeners();
    return _step;
  }

  /// Move to previous page. Returns target page when page changed.
  int? back(CalorieGoalCalculatorFormState formState) {
    if (_step <= 0) {
      return null;
    }

    _step--;
    if (currentStep == CalorieOnboardingStep.pace &&
        formState.goalMode == CalorieGoalMode.maintain) {
      _step--;
    }
    notifyListeners();
    return _step;
  }

  /// Hide currently visible validation errors.
  void clearErrors() {
    if (!_showErrors) {
      return;
    }
    _showErrors = false;
    notifyListeners();
  }

  /// Start saving.
  void startSaving() {
    _isSaving = true;
    notifyListeners();
  }

  /// Stop saving after a failed save.
  void stopSavingAfterFailure() {
    _isSaving = false;
    notifyListeners();
  }

  /// Allow route exit after successful save.
  void markRouteExitAllowed() {
    _allowRouteExit = true;
    notifyListeners();
  }
}
