import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/personal_info_gender_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/personal_info_slider_card.dart';
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
    final hasSexError = showErrors && state.sexError != null;

    return OnboardingStepContent(
      title: l10n.onboardingPersonalInfoTitle,
      subtitle: l10n.onboardingPersonalInfoSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),

        // Gender Label
        Text(
          l10n.caloriesCalculatorSexLabel,
          style: TextStyle(
            fontSize: AppFontSizes.bodyMedium,
            fontWeight: FontWeight.w600,
            color: hasSexError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Gender Options
        Row(
          children: [
            PersonalInfoGenderCard(
              label: l10n.caloriesCalculatorSexFemale,
              icon: Icons.female,
              isSelected: state.sex == CalorieCalculatorSex.female,
              hasError: hasSexError,
              onTap: () => notifier.updateSex(CalorieCalculatorSex.female),
            ),
            const SizedBox(width: AppSpacing.md),
            PersonalInfoGenderCard(
              label: l10n.caloriesCalculatorSexMale,
              icon: Icons.male,
              isSelected: state.sex == CalorieCalculatorSex.male,
              hasError: hasSexError,
              onTap: () => notifier.updateSex(CalorieCalculatorSex.male),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Age Card
        PersonalInfoSliderCard(
          label: l10n.caloriesCalculatorAgeLabel,
          unit: l10n.onboardingAgeYearsUnit,
          icon: Icons.cake_outlined,
          valueText: state.ageYearsText,
          errorText: _getAgeError(state.ageError, l10n),
          onChanged: notifier.updateAgeYears,
        ),
        const SizedBox(height: AppSpacing.md),

        // Height Card
        PersonalInfoSliderCard(
          label: l10n.caloriesCalculatorHeightLabel,
          unit: l10n.onboardingHeightCmUnit,
          icon: Icons.straighten_outlined,
          valueText: state.heightCmText,
          errorText: _getHeightError(state.heightError, l10n),
          onChanged: notifier.updateHeightCm,
          minValue: 120,
          maxValue: 230,
          defaultValue: 175,
          majorInterval: 10,
        ),
      ],
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
