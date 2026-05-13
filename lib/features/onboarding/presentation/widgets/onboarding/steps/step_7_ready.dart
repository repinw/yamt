import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calorie_goal/presentation/widgets/calorie_goal_calculator_results.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Final onboarding step that saves the calculated goal.
class Step7Ready extends StatelessWidget {
  /// Creates ready onboarding step.
  const Step7Ready({
    required this.onFinish,
    required this.isSaving,
    required this.calculation,
    super.key,
  });

  /// Called when user finishes onboarding.
  final VoidCallback onFinish;

  /// Whether save is in progress.
  final bool isSaving;

  /// Calculation preview shown before saving.
  final CalorieGoalCalculationResult? calculation;

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
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.onboardingReadyTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingReadySubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (calculation != null) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: CalorieGoalCalculatorResultsCard(
                calculation: calculation!,
              ),
            ),
            if (calculation!.wasClampedToMinimum) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: CalorieGoalCalculatorWarningCard(
                  message: l10n.caloriesCalculatorMinimumGoalWarning(1200),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isSaving ? null : onFinish,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSaving
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      l10n.onboardingFinishAction,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
