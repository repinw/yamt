import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> showCalorieGoalCalculatorSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalorieGoalCalculatorSheet(initialSettings: initialSettings);
    },
  );
}

class CalorieGoalCalculatorSheet extends ConsumerStatefulWidget {
  const CalorieGoalCalculatorSheet({super.key, required this.initialSettings});

  final CalorieGoalSettings initialSettings;

  @override
  ConsumerState<CalorieGoalCalculatorSheet> createState() =>
      _CalorieGoalCalculatorSheetState();
}

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

class _CalorieGoalCalculatorSheetState
    extends ConsumerState<CalorieGoalCalculatorSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _activityLevelController;
  late final TextEditingController _goalSpeedController;
  var _currentStep = _CalculatorOnboardingStep.sex;

  @override
  void initState() {
    super.initState();
    final initialState = CalorieGoalCalculatorFormState.initial(
      widget.initialSettings.calculatorProfile,
    );
    _weightController = TextEditingController(text: initialState.weightKgText);
    _heightController = TextEditingController(text: initialState.heightCmText);
    _ageController = TextEditingController(text: initialState.ageYearsText);
    _activityLevelController = TextEditingController(
      text: initialState.activityLevelText,
    );
    _goalSpeedController = TextEditingController(
      text: initialState.goalSpeedKgPerWeekText,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _activityLevelController.dispose();
    _goalSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final state = ref.watch(formProvider);
    final currentStep = _effectiveStep(state.goalMode);
    final visibleSteps = _visibleSteps(state.goalMode);
    final currentStepIndex = visibleSteps.indexOf(currentStep) + 1;
    final totalSteps = visibleSteps.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppInventoryEditorial.cardRadius,
            ),
          ),
          child: Padding(
            padding: AppInsets.card,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.caloriesCalculatorSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                      key: ValueKey<_CalculatorOnboardingStep>(currentStep),
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
                        child: currentStep == _CalculatorOnboardingStep.sex
                            ? TextButton(
                                onPressed: state.isSaving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(
                                  l10n.inventoryReceiptReviewCancelAction,
                                ),
                              )
                            : TextButton(
                                key: CalorieGoalCalculatorSheetKeys.backButton,
                                onPressed: state.isSaving
                                    ? null
                                    : () => _goToPreviousStep(state.goalMode),
                                child: Text(l10n.caloriesCalculatorBackAction),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: currentStep == _CalculatorOnboardingStep.results
                            ? FilledButton(
                                key: CalorieGoalCalculatorSheetKeys.saveButton,
                                onPressed: state.canSave && !state.isSaving
                                    ? _save
                                    : null,
                                child: state.isSaving
                                    ? const SizedBox.square(
                                        dimension:
                                            AppSizes.inlineProgressIndicator,
                                        child: CircularProgressIndicator(
                                          strokeWidth:
                                              AppSizes.progressStrokeWidth,
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
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final saved = await ref.read(formProvider.notifier).save();
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
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
        return _SexSegmentedControl(
          selectedSex: state.sex,
          onSelected: (sex) {
            ref.read(formProvider.notifier).updateSex(sex);
          },
        );
      case _CalculatorOnboardingStep.weight:
        return _NumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.weightField,
          controller: _weightController,
          label: l10n.caloriesCalculatorWeightLabel,
          errorText: _weightErrorText(l10n, state.weightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateWeightKg,
        );
      case _CalculatorOnboardingStep.height:
        return _NumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.heightField,
          controller: _heightController,
          label: l10n.caloriesCalculatorHeightLabel,
          errorText: _heightErrorText(l10n, state.heightError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateHeightCm,
        );
      case _CalculatorOnboardingStep.age:
        return _NumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.ageField,
          controller: _ageController,
          label: l10n.caloriesCalculatorAgeLabel,
          errorText: _ageErrorText(l10n, state.ageError),
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateAgeYears,
        );
      case _CalculatorOnboardingStep.activityLevel:
        return _NumberField(
          fieldKey: CalorieGoalCalculatorSheetKeys.activityLevelField,
          controller: _activityLevelController,
          label: l10n.caloriesCalculatorActivityLevelLabel,
          hintText: l10n.caloriesCalculatorActivityLevelHint,
          errorText: _activityErrorText(l10n, state.activityLevelError),
          autofocus: true,
          onChanged: ref.read(formProvider.notifier).updateActivityLevel,
        );
      case _CalculatorOnboardingStep.goalMode:
        return _GoalModeSegmentedControl(
          selectedGoalMode: state.goalMode,
          onSelected: (goalMode) {
            ref.read(formProvider.notifier).updateGoalMode(goalMode);
            _syncGoalSpeedText(ref.read(formProvider).goalSpeedKgPerWeekText);
          },
        );
      case _CalculatorOnboardingStep.goalSpeed:
        return _NumberField(
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
              _CalculationResultsCard(calculation: state.calculation!),
            if (state.calculation?.wasClampedToMinimum ?? false) ...[
              const SizedBox(height: AppSpacing.md),
              _WarningCard(
                message: l10n.caloriesCalculatorMinimumGoalWarning(1200),
              ),
            ],
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
      _CalculatorOnboardingStep.activityLevel =>
        state.activityLevelError == null,
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
    setState(() {
      _currentStep = visibleSteps[currentIndex + 1];
    });
  }

  void _goToPreviousStep(CalorieGoalMode goalMode) {
    final visibleSteps = _visibleSteps(goalMode);
    final currentStep = _effectiveStep(goalMode);
    final currentIndex = visibleSteps.indexOf(currentStep);
    if (currentIndex <= 0) {
      return;
    }
    setState(() {
      _currentStep = visibleSteps[currentIndex - 1];
    });
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

  String? _activityErrorText(
    AppLocalizations l10n,
    CalorieCalculatorFieldError? error,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty =>
        l10n.caloriesCalculatorActivityLevelEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorActivityLevelInvalid,
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
    this.hintText,
    this.errorText,
    this.keyboardType,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      keyboardType:
          keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}

class _SexSegmentedControl extends StatelessWidget {
  const _SexSegmentedControl({
    required this.selectedSex,
    required this.onSelected,
  });

  final CalorieCalculatorSex selectedSex;
  final ValueChanged<CalorieCalculatorSex> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<CalorieCalculatorSex>(
      key: CalorieGoalCalculatorSheetKeys.sexSegment,
      showSelectedIcon: false,
      segments: <ButtonSegment<CalorieCalculatorSex>>[
        ButtonSegment<CalorieCalculatorSex>(
          value: CalorieCalculatorSex.male,
          label: Text(l10n.caloriesCalculatorSexMale),
        ),
        ButtonSegment<CalorieCalculatorSex>(
          value: CalorieCalculatorSex.female,
          label: Text(l10n.caloriesCalculatorSexFemale),
        ),
      ],
      selected: <CalorieCalculatorSex>{selectedSex},
      onSelectionChanged: (selection) {
        final nextValue = selection.firstOrNull;
        if (nextValue != null) {
          onSelected(nextValue);
        }
      },
    );
  }
}

class _GoalModeSegmentedControl extends StatelessWidget {
  const _GoalModeSegmentedControl({
    required this.selectedGoalMode,
    required this.onSelected,
  });

  final CalorieGoalMode selectedGoalMode;
  final ValueChanged<CalorieGoalMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<CalorieGoalMode>(
      key: CalorieGoalCalculatorSheetKeys.goalModeSegment,
      showSelectedIcon: false,
      segments: <ButtonSegment<CalorieGoalMode>>[
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.lose,
          label: Text(l10n.caloriesCalculatorGoalModeLose),
        ),
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.maintain,
          label: Text(l10n.caloriesCalculatorGoalModeMaintain),
        ),
        ButtonSegment<CalorieGoalMode>(
          value: CalorieGoalMode.gain,
          label: Text(l10n.caloriesCalculatorGoalModeGain),
        ),
      ],
      selected: <CalorieGoalMode>{selectedGoalMode},
      onSelectionChanged: (selection) {
        final nextValue = selection.firstOrNull;
        if (nextValue != null) {
          onSelected(nextValue);
        }
      },
    );
  }
}

class _CalculationResultsCard extends StatelessWidget {
  const _CalculationResultsCard({required this.calculation});

  final CalorieGoalCalculationResult calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.resultsCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(label: l10n.caloriesCalculatorResultsTitle),
            const SizedBox(height: AppSpacing.md),
            _ResultRow(
              label: l10n.caloriesCalculatorBmrLabel,
              value:
                  '${numberFormat.format(calculation.bmrKcal.round())} $kcalUnit',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ResultRow(
              label: l10n.caloriesCalculatorTdeeLabel,
              value:
                  '${numberFormat.format(calculation.tdeeKcal.round())} '
                  '$kcalUnit',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ResultRow(
              label: l10n.caloriesCalculatorDailyGoalLabel,
              value:
                  '${numberFormat.format(calculation.finalGoalKcal.round())} '
                  '$kcalUnit',
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: CalorieGoalCalculatorSheetKeys.warningCard,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
