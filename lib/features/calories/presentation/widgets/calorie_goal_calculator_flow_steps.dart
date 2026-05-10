part of 'calorie_goal_calculator_flow.dart';

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
