import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step for daily activity level.
class Step2Activity extends StatelessWidget {
  /// Creates activity onboarding step.
  const Step2Activity({
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

    return Padding(
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
            l10n.onboardingActivityLevelTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.onboardingActivityLevelSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: CalorieActivityLevelOption.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final option = CalorieActivityLevelOption.values[index];
                final isSelected = state.activityLevelOption == option;

                return GestureDetector(
                  onTap: () => notifier.updateActivityLevel(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activityLevelTitle(l10n, option),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _activityLevelDescription(l10n, option),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        )
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
                                    ).colorScheme.surfaceContainerHigh,
                              width: 2,
                            ),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _activityLevelTitle(
    AppLocalizations l10n,
    CalorieActivityLevelOption option,
  ) {
    switch (option) {
      case CalorieActivityLevelOption.none:
        return l10n.caloriesCalculatorActivityLevelNoneTitle;
      case CalorieActivityLevelOption.low:
        return l10n.caloriesCalculatorActivityLevelLowTitle;
      case CalorieActivityLevelOption.medium:
        return l10n.caloriesCalculatorActivityLevelMediumTitle;
      case CalorieActivityLevelOption.high:
        return l10n.caloriesCalculatorActivityLevelHighTitle;
      case CalorieActivityLevelOption.extreme:
        return l10n.caloriesCalculatorActivityLevelExtremeTitle;
    }
  }

  String _activityLevelDescription(
    AppLocalizations l10n,
    CalorieActivityLevelOption option,
  ) {
    switch (option) {
      case CalorieActivityLevelOption.none:
        return l10n.caloriesCalculatorActivityLevelNoneDescription;
      case CalorieActivityLevelOption.low:
        return l10n.caloriesCalculatorActivityLevelLowDescription;
      case CalorieActivityLevelOption.medium:
        return l10n.caloriesCalculatorActivityLevelMediumDescription;
      case CalorieActivityLevelOption.high:
        return l10n.caloriesCalculatorActivityLevelHighDescription;
      case CalorieActivityLevelOption.extreme:
        return l10n.caloriesCalculatorActivityLevelExtremeDescription;
    }
  }
}
