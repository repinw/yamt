import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/onboarding_selectable_card.dart';
import 'package:yamt/features/calories/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step for choosing goal start date.
class Step6StartDate extends StatelessWidget {
  /// Creates start-date onboarding step.
  const Step6StartDate({
    required this.startNow,
    required this.todayMode,
    required this.catchUpEstimate,
    required this.futureGoalStartDate,
    required this.showErrors,
    required this.onStartNowChanged,
    required this.onTodayModeChanged,
    required this.onCatchUpEstimateChanged,
    required this.onFutureGoalStartChangeRequested,
    super.key,
  });

  /// Whether the user starts tracking today.
  final bool? startNow;

  /// How today should be handled when starting now.
  final CalorieGoalOnboardingTodayTracking? todayMode;

  /// Selected rough estimate for eaten calories today.
  final CalorieGoalOnboardingCatchUpEstimate catchUpEstimate;

  /// Selected future goal start date.
  final DateTime futureGoalStartDate;

  /// Whether validation errors should be shown.
  final bool showErrors;

  /// Called when start-now choice changes.
  final ValueChanged<bool> onStartNowChanged;

  /// Called when today handling mode changes.
  final ValueChanged<CalorieGoalOnboardingTodayTracking> onTodayModeChanged;

  /// Called when catch-up estimate changes.
  final ValueChanged<CalorieGoalOnboardingCatchUpEstimate>
  onCatchUpEstimateChanged;

  /// Called when the future start date should be changed.
  final VoidCallback onFutureGoalStartChangeRequested;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);
    final catchUpLowLabel = l10n.caloriesCalculatorOnboardingCatchUpLowAction;
    final catchUpNormalLabel =
        l10n.caloriesCalculatorOnboardingCatchUpNormalAction;
    final catchUpHighLabel = l10n.caloriesCalculatorOnboardingCatchUpHighAction;
    final chooseFutureDateLabel =
        l10n.caloriesCalculatorOnboardingChooseFutureDateAction;
    final startNowSelected = startNow == true;
    final startLaterSelected = startNow == false;

    return OnboardingStepContent(
      key: CalorieGoalCalculatorSheetKeys.goalStartCard,
      title: l10n.onboardingStartDateTitle,
      subtitle: l10n.onboardingStartDateSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),
        _buildOption(
          key: CalorieGoalCalculatorSheetKeys.goalStartNowOption,
          context: context,
          title: l10n.onboardingStartDateNowLabel,
          description: l10n.onboardingStartDateNowDesc,
          icon: Icons.today,
          isSelected: startNowSelected,
          onTap: () => onStartNowChanged(true),
          child: startNowSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingStartDateNowQuestion,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSubOption(
                        key: CalorieGoalCalculatorSheetKeys
                            .todayTrackingExactOption,
                        context: context,
                        title: l10n.onboardingStartDateNowExact,
                        isSelected:
                            todayMode ==
                            CalorieGoalOnboardingTodayTracking.exact,
                        onTap: () => onTodayModeChanged(
                          CalorieGoalOnboardingTodayTracking.exact,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSubOption(
                        key: CalorieGoalCalculatorSheetKeys
                            .todayTrackingEstimateOption,
                        context: context,
                        title: l10n.onboardingStartDateNowEstimate,
                        isSelected:
                            todayMode ==
                            CalorieGoalOnboardingTodayTracking.estimate,
                        onTap: () => onTodayModeChanged(
                          CalorieGoalOnboardingTodayTracking.estimate,
                        ),
                      ),
                      if (todayMode ==
                          CalorieGoalOnboardingTodayTracking.estimate) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.caloriesCalculatorOnboardingCatchUpHint,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEstimateButton(
                                key: CalorieGoalCalculatorSheetKeys
                                    .catchUpLowOption,
                                context: context,
                                title: catchUpLowLabel,
                                isSelected:
                                    catchUpEstimate ==
                                    CalorieGoalOnboardingCatchUpEstimate.low,
                                onTap: () => onCatchUpEstimateChanged(
                                  CalorieGoalOnboardingCatchUpEstimate.low,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _buildEstimateButton(
                                key: CalorieGoalCalculatorSheetKeys
                                    .catchUpNormalOption,
                                context: context,
                                title: catchUpNormalLabel,
                                isSelected:
                                    catchUpEstimate ==
                                    CalorieGoalOnboardingCatchUpEstimate.normal,
                                onTap: () => onCatchUpEstimateChanged(
                                  CalorieGoalOnboardingCatchUpEstimate.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _buildEstimateButton(
                                key: CalorieGoalCalculatorSheetKeys
                                    .catchUpHighOption,
                                context: context,
                                title: catchUpHighLabel,
                                isSelected:
                                    catchUpEstimate ==
                                    CalorieGoalOnboardingCatchUpEstimate.high,
                                onTap: () => onCatchUpEstimateChanged(
                                  CalorieGoalOnboardingCatchUpEstimate.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildOption(
          key: CalorieGoalCalculatorSheetKeys.goalStartLaterOption,
          context: context,
          title: l10n.caloriesCalculatorOnboardingStartLaterAction,
          description: l10n.onboardingStartDateLaterDesc,
          icon: Icons.event,
          isSelected: startLaterSelected,
          onTap: () => onStartNowChanged(false),
          child: startLaterSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(futureGoalStartDate),
                        key: CalorieGoalCalculatorSheetKeys.goalStartValue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.caloriesCalculatorOnboardingStartLaterHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        key: CalorieGoalCalculatorSheetKeys
                            .goalStartChangeButton,
                        onPressed: onFutureGoalStartChangeRequested,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(chooseFutureDateLabel),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        if (showErrors && startNow == null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.caloriesCalculatorOnboardingStartTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (showErrors && startNowSelected && todayMode == null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.caloriesCalculatorOnboardingTodayTrackingLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return OnboardingSelectableCard(
      key: key,
      isSelected: isSelected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ?child,
        ],
      ),
    );
  }

  Widget _buildSubOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: key,
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
                : Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
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
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: key,
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
                : Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
