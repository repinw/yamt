import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_activity_level_selector.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_input_controls.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_results.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_food_tracking_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _CalculatorStep {
  sex,
  weight,
  height,
  age,
  activityLevel,
  goalMode,
  goalSpeed,
  results,
}

/// Defines calorie goal calculator flow.
class CalorieGoalCalculatorFlow extends ConsumerStatefulWidget {
  /// The calorie goal calculator flow.
  const CalorieGoalCalculatorFlow({
    required this.initialSettings,
    super.key,
  });

  /// The initial settings.
  final CalorieGoalSettings initialSettings;

  @override
  ConsumerState<CalorieGoalCalculatorFlow> createState() =>
      _CalorieGoalCalculatorFlowState();
}

class _CalorieGoalCalculatorFlowState
    extends ConsumerState<CalorieGoalCalculatorFlow> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _goalSpeedController;
  late DateTime _goalStartDate;
  _CalculatorStep _currentStep = _CalculatorStep.sex;

  @override
  void initState() {
    super.initState();
    final initialState = CalorieGoalCalculatorFormState.initial(
      widget.initialSettings.calculatorProfile,
    );
    if (!kReleaseMode) {
      final source = widget.initialSettings.calculatorProfile == null
          ? 'defaults'
          : 'saved_profile';
      final calculation = initialState.calculation;
      final message =
          'CALC_FLOW_DEBUG '
          'init source=$source '
          'hasGoal=${widget.initialSettings.hasGoal} '
          'dailyGoalKcal=${widget.initialSettings.dailyKcalGoal} '
          'sex=${initialState.sex?.name ?? 'null'} '
          'weightKg=${initialState.weightKgText} '
          'heightCm=${initialState.heightCmText} '
          'ageYears=${initialState.ageYearsText} '
          'activityLevel=${initialState.activityLevelOption.palValue} '
          'goalMode=${initialState.goalMode.name} '
          'goalSpeedKgPerWeek=${initialState.goalSpeedKgPerWeekText} '
          'tdeeKcal=${calculation?.tdeeKcal.toStringAsFixed(2) ?? 'null'} '
          'finalGoalKcal='
          '${calculation?.finalGoalKcal.toStringAsFixed(2) ?? 'null'}';
      log(message, name: 'CalorieGoalCalculatorFlow');
    }
    _weightController = TextEditingController(text: initialState.weightKgText);
    _heightController = TextEditingController(text: initialState.heightCmText);
    _ageController = TextEditingController(text: initialState.ageYearsText);
    _goalSpeedController = TextEditingController(
      text: initialState.goalSpeedKgPerWeekText,
    );
    final initialGoalEntry =
        widget.initialSettings.activeGoalEntryForDay(DateTime.now()) ??
        widget.initialSettings.latestGoalEntry;
    _goalStartDate = CalorieGoalStartPicker.normalizeDate(
      initialGoalEntry?.effectiveCountingStartDate ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _goalSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildBottomSheet(context, l10n);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final formNotifier = ref.read(formProvider.notifier);
    final logRepository = ref.read(calorieLogRepositoryProvider);
    final allowsFutureGoalStart = _goalStartDate.isAfter(
      CalorieGoalStartPicker.normalizeDate(DateTime.now()),
    );
    final countGoalStartDayForLearning =
        await _resolveCountGoalStartDayForLearning(logRepository);
    if (countGoalStartDayForLearning == null && _shouldAskTrackedFoodToday) {
      return;
    }
    final saved = await formNotifier.save(
      goalStartDate: _goalStartDate,
      allowFutureGoalStart: allowsFutureGoalStart,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.caloriesCalculatorSaveFailed)),
      );
  }

  void _syncGoalSpeedText(String value) {
    if (_goalSpeedController.text == value) {
      return;
    }
    _goalSpeedController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _setCurrentStep(_CalculatorStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _pickGoalStart() async {
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartDate: _goalStartDate,
      now: DateTime.now(),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    if (CalorieGoalStartPicker.isSameDay(_goalStartDate, pickedDate)) {
      return;
    }

    setState(() {
      _goalStartDate = pickedDate;
    });
  }

  bool get _startsToday {
    return CalorieGoalStartPicker.isSameDay(
      _goalStartDate,
      CalorieGoalStartPicker.normalizeDate(DateTime.now()),
    );
  }

  bool get _shouldAskTrackedFoodToday {
    return _startsToday;
  }

  Future<bool?> _resolveCountGoalStartDayForLearning(
    CalorieLogRepositoryContract logRepository,
  ) async {
    if (!_shouldAskTrackedFoodToday) {
      return null;
    }
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    final entries = await logRepository.readEntriesForDay(today);
    if (!mounted) {
      return null;
    }
    return showCalorieGoalStartFoodTrackingDialog(
      context,
      entryCount: entries.length,
    );
  }
}

extension _CalorieGoalCalculatorFlowLayout on _CalorieGoalCalculatorFlowState {
  bool _canSaveResults(CalorieGoalCalculatorFormState state) {
    return state.canSave && !state.isSaving;
  }

  Widget _buildBottomSheet(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: _buildCard(context: context, l10n: l10n),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    final colors = Theme.of(context).colorScheme;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final state = ref.watch(formProvider);
    final currentStep = _effectiveStep(state.goalMode);
    final visibleSteps = _visibleSteps(state.goalMode);
    final currentStepIndex = visibleSteps.indexOf(currentStep) + 1;
    final totalSteps = visibleSteps.length;

    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.caloriesCalculatorSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.caloriesCalculatorStepProgress(
                  currentStepIndex,
                  totalSteps,
                ),
                key: CalorieGoalCalculatorSheetKeys.stepCounter,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _StepPanel(
                  key: ValueKey<_CalculatorStep>(currentStep),
                  title: _titleForStep(currentStep, l10n),
                  child: _buildStepContent(
                    context: context,
                    l10n: l10n,
                    state: state,
                    step: currentStep,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildLeadingAction(
                      context: context,
                      l10n: l10n,
                      state: state,
                      currentStep: currentStep,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: currentStep == _CalculatorStep.results
                        ? FilledButton(
                            key: CalorieGoalCalculatorSheetKeys.saveButton,
                            onPressed: _canSaveResults(state) ? _save : null,
                            child: state.isSaving
                                ? const SizedBox.square(
                                    dimension: AppSizes.inlineProgressIndicator,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppSizes.progressStrokeWidth,
                                    ),
                                  )
                                : Text(l10n.caloriesCalculatorSaveAction),
                          )
                        : FilledButton(
                            key: CalorieGoalCalculatorSheetKeys.nextButton,
                            onPressed: _canContinue(currentStep, state)
                                ? () => _goToNextStep(state.goalMode)
                                : null,
                            child: Text(l10n.caloriesCalculatorNextAction),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingAction({
    required BuildContext context,
    required AppLocalizations l10n,
    required CalorieGoalCalculatorFormState state,
    required _CalculatorStep currentStep,
  }) {
    if (currentStep != _CalculatorStep.sex) {
      return TextButton(
        key: CalorieGoalCalculatorSheetKeys.backButton,
        onPressed: state.isSaving
            ? null
            : () => _goToPreviousStep(state.goalMode),
        child: Text(l10n.caloriesCalculatorBackAction),
      );
    }

    return TextButton(
      onPressed: state.isSaving ? null : () => Navigator.of(context).pop(),
      child: Text(l10n.inventoryReceiptReviewCancelAction),
    );
  }
}

extension _CalorieGoalCalculatorFlowSteps on _CalorieGoalCalculatorFlowState {
  Widget _buildStepContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required CalorieGoalCalculatorFormState state,
    required _CalculatorStep step,
  }) {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );

    switch (step) {
      case _CalculatorStep.sex:
        return CalorieGoalCalculatorSexSegmentedControl(
          selectedSex: state.sex ?? CalorieCalculatorSex.male,
          onSelected: (sex) {
            ref.read(formProvider.notifier).updateSex(sex);
          },
        );
      case _CalculatorStep.weight:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.weightField,
          controller: _weightController,
          label: l10n.caloriesCalculatorWeightLabel,
          errorText: _weightErrorText(l10n, state.weightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateWeightKg,
        );
      case _CalculatorStep.height:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.heightField,
          controller: _heightController,
          label: l10n.caloriesCalculatorHeightLabel,
          errorText: _heightErrorText(l10n, state.heightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateHeightCm,
        );
      case _CalculatorStep.age:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.ageField,
          controller: _ageController,
          label: l10n.caloriesCalculatorAgeLabel,
          errorText: _ageErrorText(l10n, state.ageError),
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateAgeYears,
        );
      case _CalculatorStep.activityLevel:
        return CalorieGoalCalculatorActivityLevelSelector(
          selectedOption: state.activityLevelOption,
          onSelected: ref.read(formProvider.notifier).updateActivityLevel,
        );
      case _CalculatorStep.goalMode:
        return CalorieGoalCalculatorGoalModeSegmentedControl(
          selectedGoalMode: state.goalMode,
          onSelected: (goalMode) {
            ref.read(formProvider.notifier).updateGoalMode(goalMode);
            _syncGoalSpeedText(ref.read(formProvider).goalSpeedKgPerWeekText);
          },
        );
      case _CalculatorStep.goalSpeed:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.goalSpeedField,
          controller: _goalSpeedController,
          label: l10n.caloriesCalculatorGoalSpeedLabel,
          hintText: l10n.caloriesCalculatorGoalSpeedHint,
          errorText: _goalSpeedErrorText(l10n, state.goalSpeedError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateGoalSpeedKgPerWeek,
        );
      case _CalculatorStep.results:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.calculation != null)
              CalorieGoalCalculatorResultsCard(calculation: state.calculation!),
            if (state.calculation?.wasClampedToMinimum ?? false) ...[
              const SizedBox(height: AppSpacing.md),
              CalorieGoalCalculatorWarningCard(
                message: l10n.caloriesCalculatorMinimumGoalWarning(1200),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            CalorieGoalCalculatorGoalStartCard(
              goalStartDate: _goalStartDate,
              enabled: !state.isSaving,
              onChangeRequested: _pickGoalStart,
            ),
          ],
        );
    }
  }

  bool _canContinue(
    _CalculatorStep step,
    CalorieGoalCalculatorFormState state,
  ) {
    return switch (step) {
      _CalculatorStep.sex => true,
      _CalculatorStep.weight => state.weightError == null,
      _CalculatorStep.height => state.heightError == null,
      _CalculatorStep.age => state.ageError == null,
      _CalculatorStep.activityLevel => true,
      _CalculatorStep.goalMode => true,
      _CalculatorStep.goalSpeed => state.goalSpeedError == null,
      _CalculatorStep.results => false,
    };
  }

  void _goToNextStep(CalorieGoalMode goalMode) {
    final visibleSteps = _visibleSteps(goalMode);
    final currentStep = _effectiveStep(goalMode);
    final currentIndex = visibleSteps.indexOf(currentStep);
    if (currentIndex < 0 || currentIndex >= visibleSteps.length - 1) {
      return;
    }
    _setCurrentStep(visibleSteps[currentIndex + 1]);
  }

  void _goToPreviousStep(CalorieGoalMode goalMode) {
    final visibleSteps = _visibleSteps(goalMode);
    final currentStep = _effectiveStep(goalMode);
    final currentIndex = visibleSteps.indexOf(currentStep);
    if (currentIndex <= 0) {
      return;
    }
    _setCurrentStep(visibleSteps[currentIndex - 1]);
  }

  _CalculatorStep _effectiveStep(CalorieGoalMode goalMode) {
    if (_currentStep == _CalculatorStep.goalSpeed &&
        goalMode == CalorieGoalMode.maintain) {
      return _CalculatorStep.results;
    }
    return _currentStep;
  }

  List<_CalculatorStep> _visibleSteps(CalorieGoalMode goalMode) {
    return <_CalculatorStep>[
      _CalculatorStep.sex,
      _CalculatorStep.weight,
      _CalculatorStep.height,
      _CalculatorStep.age,
      _CalculatorStep.activityLevel,
      _CalculatorStep.goalMode,
      if (goalMode != CalorieGoalMode.maintain) _CalculatorStep.goalSpeed,
      _CalculatorStep.results,
    ];
  }

  String _titleForStep(_CalculatorStep step, AppLocalizations l10n) {
    return switch (step) {
      _CalculatorStep.sex => l10n.caloriesCalculatorSexLabel,
      _CalculatorStep.weight => l10n.caloriesCalculatorWeightLabel,
      _CalculatorStep.height => l10n.caloriesCalculatorHeightLabel,
      _CalculatorStep.age => l10n.caloriesCalculatorAgeLabel,
      _CalculatorStep.activityLevel =>
        l10n.caloriesCalculatorActivityLevelLabel,
      _CalculatorStep.goalMode => l10n.caloriesCalculatorGoalModeLabel,
      _CalculatorStep.goalSpeed => l10n.caloriesCalculatorGoalSpeedLabel,
      _CalculatorStep.results => l10n.caloriesCalculatorResultsTitle,
    };
  }

  String? _weightErrorText(
    AppLocalizations l10n,
    CalorieCalculatorFieldError? error,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorWeightEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorWeightInvalid,
      null => null,
    };
  }

  String? _heightErrorText(
    AppLocalizations l10n,
    CalorieCalculatorFieldError? error,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorHeightEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorHeightInvalid,
      null => null,
    };
  }

  String? _ageErrorText(
    AppLocalizations l10n,
    CalorieCalculatorFieldError? error,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorAgeEmpty,
      CalorieCalculatorFieldError.invalid => l10n.caloriesCalculatorAgeInvalid,
      null => null,
    };
  }

  String? _goalSpeedErrorText(
    AppLocalizations l10n,
    CalorieCalculatorFieldError? error,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty =>
        l10n.caloriesCalculatorGoalSpeedEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorGoalSpeedInvalid,
      null => null,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(label: title),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
