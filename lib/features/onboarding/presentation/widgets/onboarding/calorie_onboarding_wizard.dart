import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calorie_goal/presentation/widgets/calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_finish_handler.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_start_date_controller.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_step_pages.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard_chrome.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_wizard_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Full-screen calorie goal onboarding wizard.
class CalorieOnboardingWizard extends ConsumerStatefulWidget {
  /// Creates calorie onboarding wizard.
  const CalorieOnboardingWizard({
    required this.initialSettings,
    super.key,
  });

  /// Initial calorie settings used to seed the calculator.
  final CalorieGoalSettings initialSettings;

  @override
  ConsumerState<CalorieOnboardingWizard> createState() =>
      _CalorieOnboardingWizardState();
}

class _CalorieOnboardingWizardState
    extends ConsumerState<CalorieOnboardingWizard> {
  final PageController _pageController = PageController();
  late final CalorieOnboardingWizardController _wizardController;
  late final CalorieOnboardingStartDateController _startDateController;

  @override
  void initState() {
    super.initState();
    _wizardController = CalorieOnboardingWizardController()
      ..addListener(_handleWizardStateChanged);
    _startDateController = CalorieOnboardingStartDateController()
      ..addListener(_handleWizardStateChanged);
  }

  void _handleWizardStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleNext() async {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
      useEmptyDefaults: true,
    );
    final formState = ref.read(formProvider);
    final targetStep = _wizardController.next(
      formState,
      hasValidStartDateChoice: _startDateController.hasValidChoice,
    );
    if (targetStep == null) {
      return;
    }
    await _pageController.animateToPage(
      targetStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleFinish(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalOnboardingFinishFlow finishFlow,
  ) {
    return CalorieOnboardingFinishHandler(
      finishFlow: finishFlow,
      wizardController: _wizardController,
      startDateController: _startDateController,
    ).finish(
      context: context,
      formState: formState,
      isMounted: () => mounted,
    );
  }

  Future<void> _pickFutureGoalStartDate() async {
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartDate:
          _startDateController.futureGoalStartDate.isAfter(today)
          ? _startDateController.futureGoalStartDate
          : today.add(const Duration(days: 1)),
      now: DateTime.now(),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (pickedDate == null || !context.mounted) {
      return;
    }
    _startDateController.updateFutureGoalStartDate(pickedDate);
    _wizardController.clearErrors();
  }

  Future<void> _handleBack() async {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
      useEmptyDefaults: true,
    );
    final formState = ref.read(formProvider);
    final targetStep = _wizardController.back(formState);
    if (targetStep == null) {
      return;
    }
    await _pageController.animateToPage(
      targetStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleStartNowChanged(bool value) {
    _startDateController.updateStartNow(startNow: value);
    _wizardController.clearErrors();
  }

  void _handleTodayTrackingChanged(CalorieGoalOnboardingTodayTracking value) {
    _startDateController.updateTodayTracking(value);
    _wizardController.clearErrors();
  }

  void _handleCatchUpEstimateChanged(
    CalorieGoalOnboardingCatchUpEstimate value,
  ) {
    _startDateController.updateCatchUpEstimate(value);
  }

  @override
  void dispose() {
    _wizardController
      ..removeListener(_handleWizardStateChanged)
      ..dispose();
    _startDateController
      ..removeListener(_handleWizardStateChanged)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
      useEmptyDefaults: true,
    );
    final formState = ref.watch(formProvider);
    final formNotifier = ref.read(formProvider.notifier);
    final finishFlow = ref.watch(calorieGoalOnboardingFinishFlowProvider);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final l10n = AppLocalizations.of(context)!;
    final nextLabel =
        _wizardController.currentStep == CalorieOnboardingStep.info
        ? l10n.onboardingNextActionStep5
        : l10n.onboardingNextAction;

    return PopScope(
      canPop: _wizardController.allowRouteExit,
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: CalorieOnboardingStepPages(
                  pageController: _pageController,
                  formState: formState,
                  formNotifier: formNotifier,
                  showErrors: _wizardController.showErrors,
                  startDateController: _startDateController,
                  isSaving: _wizardController.isSaving || formState.isSaving,
                  onNext: _handleNext,
                  onStartNowChanged: _handleStartNowChanged,
                  onTodayModeChanged: _handleTodayTrackingChanged,
                  onCatchUpEstimateChanged: _handleCatchUpEstimateChanged,
                  onFutureGoalStartChangeRequested: _pickFutureGoalStartDate,
                  onFinish: () => _handleFinish(formState, finishFlow),
                ),
              ),
              if (_wizardController.showsStepChrome)
                CalorieOnboardingWizardChrome(
                  isKeyboardVisible: isKeyboardVisible,
                  progress: _wizardController.progress,
                  nextLabel: nextLabel,
                  onBack: _handleBack,
                  onNext: _handleNext,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
