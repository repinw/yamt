import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/onboarding_labeled_text_field.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step for sex, age, and height.
class Step1PersonalInfo extends StatelessWidget {
  /// Creates personal-info onboarding step.
  const Step1PersonalInfo({
    required this.state,
    required this.notifier,
    this.showErrors = false,
    super.key,
  });

  /// Current calculator form state.
  final CalorieGoalCalculatorFormState state;

  /// Calculator form notifier.
  final CalorieGoalCalculatorFormController notifier;

  /// Whether validation errors should be shown.
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OnboardingStepContent(
      title: l10n.onboardingPersonalInfoTitle,
      subtitle: l10n.onboardingPersonalInfoSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Gender
        Text(
          l10n.caloriesCalculatorSexLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: showErrors && state.sexError != null
                ? theme.colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _buildGenderButton(
              context: context,
              label: l10n.caloriesCalculatorSexFemale,
              isSelected: state.sex == CalorieCalculatorSex.female,
              hasError: showErrors && state.sexError != null,
              onTap: () => notifier.updateSex(CalorieCalculatorSex.female),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildGenderButton(
              context: context,
              label: l10n.caloriesCalculatorSexMale,
              isSelected: state.sex == CalorieCalculatorSex.male,
              hasError: showErrors && state.sexError != null,
              onTap: () => notifier.updateSex(CalorieCalculatorSex.male),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Age and Height
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: OnboardingLabeledTextField(
                label: l10n.caloriesCalculatorAgeLabel,
                hintText: l10n.caloriesCalculatorAgeLabel,
                initialValue: state.ageYearsText,
                keyboardType: TextInputType.number,
                errorText: _getAgeError(state.ageError, l10n),
                onChanged: notifier.updateAgeYears,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OnboardingLabeledTextField(
                label: l10n.caloriesCalculatorHeightLabel,
                hintText: 'cm',
                initialValue: state.heightCmText,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: _getHeightError(state.heightError, l10n),
                onChanged: notifier.updateHeightCm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (hasError
                        ? theme.colorScheme.error
                        : Theme.of(context).colorScheme.surfaceContainer),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? primary
                  : (hasError
                        ? theme.colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  String? _getAgeError(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    if (!showErrors) return null;
    switch (error) {
      case CalorieCalculatorFieldError.empty:
        return l10n.caloriesCalculatorAgeEmpty;
      case CalorieCalculatorFieldError.invalid:
        return l10n.caloriesCalculatorAgeInvalid;
      case null:
        return null;
    }
  }

  String? _getHeightError(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    if (!showErrors) return null;
    switch (error) {
      case CalorieCalculatorFieldError.empty:
        return l10n.caloriesCalculatorHeightEmpty;
      case CalorieCalculatorFieldError.invalid:
        return l10n.caloriesCalculatorHeightInvalid;
      case null:
        return null;
    }
  }
}
