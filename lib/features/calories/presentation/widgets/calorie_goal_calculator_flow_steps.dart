part of 'calorie_goal_calculator_flow.dart';

enum _CalculatorOnboardingStep {
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
    required _CalculatorOnboardingStep step,
  }) {
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );

    switch (step) {
      case _CalculatorOnboardingStep.sex:
        return CalorieGoalCalculatorSexSegmentedControl(
          selectedSex: state.sex,
          onSelected: (sex) {
            ref.read(formProvider.notifier).updateSex(sex);
          },
        );
      case _CalculatorOnboardingStep.weight:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.weightField,
          controller: _weightController,
          label: l10n.caloriesCalculatorWeightLabel,
          errorText: _weightErrorText(l10n, state.weightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateWeightKg,
        );
      case _CalculatorOnboardingStep.height:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.heightField,
          controller: _heightController,
          label: l10n.caloriesCalculatorHeightLabel,
          errorText: _heightErrorText(l10n, state.heightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateHeightCm,
        );
      case _CalculatorOnboardingStep.age:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.ageField,
          controller: _ageController,
          label: l10n.caloriesCalculatorAgeLabel,
          errorText: _ageErrorText(l10n, state.ageError),
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateAgeYears,
        );
      case _CalculatorOnboardingStep.activityLevel:
        return CalorieGoalCalculatorActivityLevelSelector(
          selectedOption: state.activityLevelOption,
          onSelected: ref.read(formProvider.notifier).updateActivityLevel,
        );
      case _CalculatorOnboardingStep.goalMode:
        return CalorieGoalCalculatorGoalModeSegmentedControl(
          selectedGoalMode: state.goalMode,
          onSelected: (goalMode) {
            ref.read(formProvider.notifier).updateGoalMode(goalMode);
            _syncGoalSpeedText(ref.read(formProvider).goalSpeedKgPerWeekText);
          },
        );
      case _CalculatorOnboardingStep.goalSpeed:
        return CalorieGoalCalculatorNumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.goalSpeedField,
          controller: _goalSpeedController,
          label: l10n.caloriesCalculatorGoalSpeedLabel,
          hintText: l10n.caloriesCalculatorGoalSpeedHint,
          errorText: _goalSpeedErrorText(l10n, state.goalSpeedError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateGoalSpeedKgPerWeek,
        );
      case _CalculatorOnboardingStep.results:
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
              goalStartAt: _goalStartAt,
              enabled: !state.isSaving,
              onChangeRequested: _pickGoalStart,
            ),
            const SizedBox(height: AppSpacing.md),
            CalorieGoalCalculatorEatingWindowCard(
              startMinuteOfDay: _eatingWindowStartMinuteOfDay,
              endMinuteOfDay: _eatingWindowEndMinuteOfDay,
              enabled: !state.isSaving,
              onChangeRequested: _pickEatingWindow,
            ),
          ],
        );
    }
  }

  bool _canContinue(
    _CalculatorOnboardingStep step,
    CalorieGoalCalculatorFormState state,
  ) {
    return switch (step) {
      _CalculatorOnboardingStep.sex => true,
      _CalculatorOnboardingStep.weight => state.weightError == null,
      _CalculatorOnboardingStep.height => state.heightError == null,
      _CalculatorOnboardingStep.age => state.ageError == null,
      _CalculatorOnboardingStep.activityLevel => true,
      _CalculatorOnboardingStep.goalMode => true,
      _CalculatorOnboardingStep.goalSpeed => state.goalSpeedError == null,
      _CalculatorOnboardingStep.results => false,
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

  _CalculatorOnboardingStep _effectiveStep(CalorieGoalMode goalMode) {
    if (_currentStep == _CalculatorOnboardingStep.goalSpeed &&
        goalMode == CalorieGoalMode.maintain) {
      return _CalculatorOnboardingStep.results;
    }
    return _currentStep;
  }

  List<_CalculatorOnboardingStep> _visibleSteps(CalorieGoalMode goalMode) {
    return <_CalculatorOnboardingStep>[
      _CalculatorOnboardingStep.sex,
      _CalculatorOnboardingStep.weight,
      _CalculatorOnboardingStep.height,
      _CalculatorOnboardingStep.age,
      _CalculatorOnboardingStep.activityLevel,
      _CalculatorOnboardingStep.goalMode,
      if (goalMode != CalorieGoalMode.maintain)
        _CalculatorOnboardingStep.goalSpeed,
      _CalculatorOnboardingStep.results,
    ];
  }

  String _titleForStep(_CalculatorOnboardingStep step, AppLocalizations l10n) {
    return switch (step) {
      _CalculatorOnboardingStep.sex => l10n.caloriesCalculatorSexLabel,
      _CalculatorOnboardingStep.weight => l10n.caloriesCalculatorWeightLabel,
      _CalculatorOnboardingStep.height => l10n.caloriesCalculatorHeightLabel,
      _CalculatorOnboardingStep.age => l10n.caloriesCalculatorAgeLabel,
      _CalculatorOnboardingStep.activityLevel =>
        l10n.caloriesCalculatorActivityLevelLabel,
      _CalculatorOnboardingStep.goalMode =>
        l10n.caloriesCalculatorGoalModeLabel,
      _CalculatorOnboardingStep.goalSpeed =>
        l10n.caloriesCalculatorGoalSpeedLabel,
      _CalculatorOnboardingStep.results => l10n.caloriesCalculatorResultsTitle,
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
  const _StepPanel({super.key, required this.title, required this.child});

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
