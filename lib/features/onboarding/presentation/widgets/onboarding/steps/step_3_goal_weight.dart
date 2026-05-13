import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_labeled_text_field.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step for current and target weight.
class Step3GoalWeight extends StatelessWidget {
  /// Creates goal-weight onboarding step.
  const Step3GoalWeight({
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

    var feedbackText = '';
    var feedbackIcon = Icons.monitor_weight_outlined;
    var feedbackColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (state.weightError == null &&
        state.targetWeightError == null &&
        state.weightKgText.isNotEmpty &&
        state.targetWeightKgText.isNotEmpty) {
      if (state.goalMode == CalorieGoalMode.lose) {
        feedbackText = l10n.onboardingGoalWeightLoseFeedback;
        feedbackIcon = Icons.trending_down;
        feedbackColor = Colors.blue;
      } else if (state.goalMode == CalorieGoalMode.gain) {
        feedbackText = l10n.onboardingGoalWeightGainFeedback;
        feedbackIcon = Icons.trending_up;
        feedbackColor = Colors.orange;
      } else {
        feedbackText = l10n.onboardingGoalWeightMaintainFeedback;
        feedbackIcon = Icons.trending_flat;
        feedbackColor = Colors.green;
      }
    }

    return OnboardingStepContent(
      title: l10n.onboardingGoalWeightTitle,
      subtitle: l10n.onboardingGoalWeightSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),

        OnboardingLabeledTextField(
          label: l10n.onboardingGoalWeightStartLabel,
          hintText: 'kg',
          initialValue: state.weightKgText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _getWeightError(state.weightError, l10n),
          onChanged: notifier.updateWeightKg,
        ),
        const SizedBox(height: AppSpacing.lg),
        OnboardingLabeledTextField(
          label: l10n.onboardingGoalWeightTargetLabel,
          hintText: 'kg',
          initialValue: state.targetWeightKgText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: state.targetWeightKgText.isEmpty && showErrors
              ? l10n.caloriesCalculatorWeightEmpty
              : _getWeightError(state.targetWeightError, l10n),
          onChanged: notifier.updateTargetWeightKg,
        ),

        if (feedbackText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feedbackColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(feedbackIcon, color: feedbackColor, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    feedbackText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: feedbackColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _getWeightError(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    if (!showErrors) return null;
    switch (error) {
      case CalorieCalculatorFieldError.empty:
        return l10n.caloriesCalculatorWeightEmpty;
      case CalorieCalculatorFieldError.invalid:
        return l10n.caloriesCalculatorWeightInvalid;
      case null:
        return null;
    }
  }
}
