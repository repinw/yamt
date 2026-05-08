import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 80,
        bottom: 120,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingPersonalInfoTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.onboardingPersonalInfoSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.caloriesCalculatorAgeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      initialValue: state.ageYearsText,
                      onChanged: notifier.updateAgeYears,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: l10n.caloriesCalculatorAgeLabel,
                        errorText: _getAgeError(state.ageError, l10n),
                        filled: true,
                        fillColor: Theme.of(context).canvasColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.caloriesCalculatorHeightLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      initialValue: state.heightCmText,
                      onChanged: notifier.updateHeightCm,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'cm',
                        errorText: _getHeightError(state.heightError, l10n),
                        filled: true,
                        fillColor: Theme.of(context).canvasColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
