import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_0_welcome.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_1_personal_info.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_2_activity.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_3_goal_weight.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_4_pace.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_5_info.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_6_start_date.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/step_7_ready.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _CalorieOnboardingStep {
  welcome,
  personalInfo,
  activity,
  goalWeight,
  pace,
  info,
  startDate,
  ready,
}

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
  int _step = 0;
  final PageController _pageController = PageController();
  bool _showErrors = false;
  bool _allowRouteExit = false;
  bool? _startNowChoice;
  CalorieGoalOnboardingTodayTracking? _todayTrackingChoice;
  late DateTime _futureGoalStartDate;

  static const List<_CalorieOnboardingStep> _steps =
      _CalorieOnboardingStep.values;
  static final int _totalSteps = _steps.length;

  _CalorieOnboardingStep get _currentStep => _steps[_step];

  @override
  void initState() {
    super.initState();
    _futureGoalStartDate = CalorieGoalStartPicker.normalizeDate(
      DateTime.now().add(const Duration(days: 1)),
    );
  }

  Future<void> _handleNext() async {
    if (_step < _totalSteps - 1) {
      final formProvider = calorieGoalCalculatorFormControllerProvider(
        widget.initialSettings.calculatorProfile,
        useEmptyDefaults: true,
      );
      final formState = ref.read(formProvider);

      if (!_isCurrentStepValid(formState)) {
        setState(() {
          _showErrors = true;
        });
        return;
      }

      setState(() {
        _step++;
        if (_currentStep == _CalorieOnboardingStep.pace &&
            formState.goalMode == CalorieGoalMode.maintain) {
          _step++;
        }
        _showErrors = false;
      });
      await _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isCurrentStepValid(CalorieGoalCalculatorFormState formState) {
    return switch (_currentStep) {
      _CalorieOnboardingStep.personalInfo =>
        formState.sexError == null &&
            formState.ageError == null &&
            formState.heightError == null,
      _CalorieOnboardingStep.goalWeight =>
        formState.weightError == null &&
            formState.targetWeightError == null &&
            formState.targetWeightKgText.isNotEmpty,
      _CalorieOnboardingStep.startDate => _hasValidStartDateChoice,
      _ => true,
    };
  }

  bool get _hasValidStartDateChoice {
    return switch (_startNowChoice) {
      true => _todayTrackingChoice != null,
      false => true,
      null => false,
    };
  }

  Future<void> _handleSave(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final startsToday = _startNowChoice == true;
    final todayTrackingChoice = _todayTrackingChoice;
    final success = await formNotifier.save(
      goalStartDate: startsToday ? DateTime.now() : _futureGoalStartDate,
      allowFutureGoalStart: true,
      countGoalStartDayForLearning: startsToday
          ? todayTrackingChoice == CalorieGoalOnboardingTodayTracking.exact
          : null,
      syncBurnWeekForOnboarding: true,
      onboardingCatchUpEstimate:
          startsToday &&
              todayTrackingChoice == CalorieGoalOnboardingTodayTracking.estimate
          ? formState.onboardingCatchUpEstimate
          : null,
      onboardingPlaceholderName: l10n.caloriesOnboardingPlaceholderName,
    );
    if (success && mounted) {
      setState(() {
        _allowRouteExit = true;
      });
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.homeDiary);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.caloriesCalculatorSaveFailed)),
        );
    }
  }

  Future<void> _pickFutureGoalStartDate() async {
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartDate: _futureGoalStartDate.isAfter(today)
          ? _futureGoalStartDate
          : today.add(const Duration(days: 1)),
      now: DateTime.now(),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() {
      _startNowChoice = false;
      _todayTrackingChoice = null;
      _futureGoalStartDate = pickedDate;
      _showErrors = false;
    });
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
      useEmptyDefaults: true,
    );
    ref.read(formProvider.notifier).updateOnboardingStartNow(startNow: false);
  }

  Future<void> _handleBack() async {
    if (_step > 0) {
      final formProvider = calorieGoalCalculatorFormControllerProvider(
        widget.initialSettings.calculatorProfile,
        useEmptyDefaults: true,
      );
      final formState = ref.read(formProvider);

      setState(() {
        _step--;
        if (_currentStep == _CalorieOnboardingStep.pace &&
            formState.goalMode == CalorieGoalMode.maintain) {
          _step--;
        }
      });
      await _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _allowRouteExit,
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep0(),
                    _buildStep1(formState, formNotifier),
                    _buildStep2(formState, formNotifier),
                    _buildStep3(formState, formNotifier),
                    _buildStep4(formState, formNotifier),
                    _buildStep5(),
                    _buildStep6(formState, formNotifier),
                    _buildStep7(formState, formNotifier),
                  ],
                ),
              ),

              if (_step > 0 && _step < _totalSteps - 1)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: Theme.of(context).canvasColor.withValues(alpha: 0.9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: _step / (_totalSteps - 1),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _handleBack,
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_step > 0 && _step < _totalSteps - 1 && !isKeyboardVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).canvasColor.withValues(alpha: 0),
                          Theme.of(context).canvasColor,
                          Theme.of(context).canvasColor,
                        ],
                        stops: const [0.0, 0.2, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xl,
                      bottom: AppSpacing.lg,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                    ),
                    child: FilledButton(
                      onPressed: _handleNext,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _CalorieOnboardingStep.info
                                ? AppLocalizations.of(
                                    context,
                                  )!.onboardingNextActionStep5
                                : AppLocalizations.of(
                                    context,
                                  )!.onboardingNextAction,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Step0Welcome(onNext: _handleNext);
  }

  Widget _buildStep1(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step1PersonalInfo(
      state: formState,
      notifier: formNotifier,
      showErrors: _showErrors,
    );
  }

  Widget _buildStep2(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step2Activity(
      state: formState,
      notifier: formNotifier,
    );
  }

  Widget _buildStep3(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step3GoalWeight(
      state: formState,
      notifier: formNotifier,
      showErrors: _showErrors,
    );
  }

  Widget _buildStep4(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step4Pace(
      state: formState,
      notifier: formNotifier,
    );
  }

  Widget _buildStep5() {
    return const Step5Info();
  }

  Widget _buildStep6(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step6StartDate(
      startNow: _startNowChoice,
      todayMode: _todayTrackingChoice,
      catchUpEstimate: formState.onboardingCatchUpEstimate,
      futureGoalStartDate: _futureGoalStartDate,
      showErrors: _showErrors,
      onStartNowChanged: (value) {
        setState(() {
          _startNowChoice = value;
          if (!value) {
            _todayTrackingChoice = null;
          }
          _showErrors = false;
        });
        formNotifier.updateOnboardingStartNow(startNow: value);
      },
      onTodayModeChanged: (value) {
        setState(() {
          _todayTrackingChoice = value;
          _showErrors = false;
        });
        formNotifier.updateOnboardingTodayTracking(value);
      },
      onCatchUpEstimateChanged: (value) {
        formNotifier.updateOnboardingCatchUpEstimate(value);
      },
      onFutureGoalStartChangeRequested: _pickFutureGoalStartDate,
    );
  }

  Widget _buildStep7(
    CalorieGoalCalculatorFormState formState,
    CalorieGoalCalculatorFormController formNotifier,
  ) {
    return Step7Ready(
      isSaving: formState.isSaving,
      calculation: formState.calculation,
      onFinish: () => _handleSave(formState, formNotifier),
    );
  }
}
