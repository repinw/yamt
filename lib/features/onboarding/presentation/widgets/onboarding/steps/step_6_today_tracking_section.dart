import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Expanded section shown when start-today is selected.
class Step6TodayTrackingSection extends StatelessWidget {
  /// Creates today tracking section.
  const Step6TodayTrackingSection({
    required this.todayMode,
    required this.catchUpEstimate,
    required this.onTodayModeChanged,
    required this.onCatchUpEstimateChanged,
    super.key,
  });

  /// Current today tracking mode.
  final CalorieGoalOnboardingTodayTracking? todayMode;

  /// Current catch-up estimate.
  final CalorieGoalOnboardingCatchUpEstimate catchUpEstimate;

  /// Called when today tracking mode changes.
  final ValueChanged<CalorieGoalOnboardingTodayTracking> onTodayModeChanged;

  /// Called when catch-up estimate changes.
  final ValueChanged<CalorieGoalOnboardingCatchUpEstimate>
  onCatchUpEstimateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEstimate = todayMode == CalorieGoalOnboardingTodayTracking.estimate;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingStartDateNowQuestion,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Step6TodayTrackingOption(
            key: CalorieGoalOnboardingKeys.todayTrackingExactOption,
            title: l10n.onboardingStartDateNowExact,
            isSelected: todayMode == CalorieGoalOnboardingTodayTracking.exact,
            onTap: () => onTodayModeChanged(
              CalorieGoalOnboardingTodayTracking.exact,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Step6TodayTrackingOption(
            key: CalorieGoalOnboardingKeys.todayTrackingEstimateOption,
            title: l10n.onboardingStartDateNowEstimate,
            isSelected: isEstimate,
            onTap: () => onTodayModeChanged(
              CalorieGoalOnboardingTodayTracking.estimate,
            ),
          ),
          if (isEstimate) ...[
            const SizedBox(height: AppSpacing.md),
            Step6CatchUpEstimateSelector(
              catchUpEstimate: catchUpEstimate,
              onChanged: onCatchUpEstimateChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/// Selectable option for today's tracking mode.
class Step6TodayTrackingOption extends StatelessWidget {
  /// Creates today tracking option.
  const Step6TodayTrackingOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// Option title.
  final String title;

  /// Whether selected.
  final bool isSelected;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surfaceContainerLow
              : Theme.of(context).canvasColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHigh,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Low/normal/high catch-up estimate selector.
class Step6CatchUpEstimateSelector extends StatelessWidget {
  /// Creates catch-up estimate selector.
  const Step6CatchUpEstimateSelector({
    required this.catchUpEstimate,
    required this.onChanged,
    super.key,
  });

  /// Current estimate.
  final CalorieGoalOnboardingCatchUpEstimate catchUpEstimate;

  /// Called when estimate changes.
  final ValueChanged<CalorieGoalOnboardingCatchUpEstimate> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.caloriesCalculatorOnboardingCatchUpHint,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Step6CatchUpEstimateButton(
                key: CalorieGoalOnboardingKeys.catchUpLowOption,
                title: l10n.caloriesCalculatorOnboardingCatchUpLowAction,
                isSelected:
                    catchUpEstimate == CalorieGoalOnboardingCatchUpEstimate.low,
                onTap: () => onChanged(
                  CalorieGoalOnboardingCatchUpEstimate.low,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Step6CatchUpEstimateButton(
                key: CalorieGoalOnboardingKeys.catchUpNormalOption,
                title: l10n.caloriesCalculatorOnboardingCatchUpNormalAction,
                isSelected:
                    catchUpEstimate ==
                    CalorieGoalOnboardingCatchUpEstimate.normal,
                onTap: () => onChanged(
                  CalorieGoalOnboardingCatchUpEstimate.normal,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Step6CatchUpEstimateButton(
                key: CalorieGoalOnboardingKeys.catchUpHighOption,
                title: l10n.caloriesCalculatorOnboardingCatchUpHighAction,
                isSelected:
                    catchUpEstimate ==
                    CalorieGoalOnboardingCatchUpEstimate.high,
                onTap: () => onChanged(
                  CalorieGoalOnboardingCatchUpEstimate.high,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Selectable catch-up estimate button.
class Step6CatchUpEstimateButton extends StatelessWidget {
  /// Creates estimate button.
  const Step6CatchUpEstimateButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// Button title.
  final String title;

  /// Whether selected.
  final bool isSelected;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHigh,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
