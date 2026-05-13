import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step for weight-change pace.
class Step4Pace extends StatelessWidget {
  /// Creates pace onboarding step.
  const Step4Pace({
    required this.state,
    required this.notifier,
    super.key,
  });

  /// Current calculator form state.
  final CalorieGoalCalculatorFormState state;

  /// Calculator form notifier.
  final CalorieGoalCalculatorFormController notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (state.goalMode == CalorieGoalMode.maintain) {
      return OnboardingStepContent(
        title: l10n.onboardingPaceTitle,
        subtitle: l10n.onboardingPaceMaintainMessage,
        children: const [],
      );
    }

    final paces = [0.25, 0.5, 0.75, 1.0];
    final currentPace = double.tryParse(state.goalSpeedKgPerWeekText) ?? 0.5;

    return OnboardingStepContent(
      title: l10n.onboardingPaceTitle,
      subtitle: l10n.onboardingPaceSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),
        ...paces.map((pace) {
          final isSelected = currentPace == pace;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => notifier.updateGoalSpeedKgPerWeek(pace.toString()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainer,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          width: isSelected ? 6 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      l10n.onboardingPacePerWeek(pace.toString()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (currentPace > 0.5) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingPaceWarningTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.goalMode == CalorieGoalMode.gain
                            ? l10n.onboardingPaceWarningGainMessage
                            : l10n.onboardingPaceWarningLoseMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
