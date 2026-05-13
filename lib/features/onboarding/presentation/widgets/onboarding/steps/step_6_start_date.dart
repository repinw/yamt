import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_6_future_start_section.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_6_start_date_choice_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/step_6_today_tracking_section.dart';
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
    final startNowSelected = startNow == true;
    final startLaterSelected = startNow == false;

    return OnboardingStepContent(
      key: CalorieGoalOnboardingKeys.goalStartCard,
      title: l10n.onboardingStartDateTitle,
      subtitle: l10n.onboardingStartDateSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Step6StartDateChoiceCard(
          key: CalorieGoalOnboardingKeys.goalStartNowOption,
          title: l10n.onboardingStartDateNowLabel,
          description: l10n.onboardingStartDateNowDesc,
          icon: Icons.today,
          isSelected: startNowSelected,
          onTap: () => onStartNowChanged(true),
          child: startNowSelected
              ? Step6TodayTrackingSection(
                  todayMode: todayMode,
                  catchUpEstimate: catchUpEstimate,
                  onTodayModeChanged: onTodayModeChanged,
                  onCatchUpEstimateChanged: onCatchUpEstimateChanged,
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Step6StartDateChoiceCard(
          key: CalorieGoalOnboardingKeys.goalStartLaterOption,
          title: l10n.caloriesCalculatorOnboardingStartLaterAction,
          description: l10n.onboardingStartDateLaterDesc,
          icon: Icons.event,
          isSelected: startLaterSelected,
          onTap: () => onStartNowChanged(false),
          child: startLaterSelected
              ? Step6FutureStartSection(
                  futureGoalStartDate: futureGoalStartDate,
                  onFutureGoalStartChangeRequested:
                      onFutureGoalStartChangeRequested,
                )
              : null,
        ),
        ?_buildError(context, l10n, startNowSelected: startNowSelected),
      ],
    );
  }

  Widget? _buildError(
    BuildContext context,
    AppLocalizations l10n, {
    required bool startNowSelected,
  }) {
    if (!showErrors) {
      return null;
    }
    final message = switch ((startNow, startNowSelected, todayMode)) {
      (null, _, _) => l10n.caloriesCalculatorOnboardingStartTitle,
      (_, true, null) => l10n.caloriesCalculatorOnboardingTodayTrackingLabel,
      _ => null,
    };
    if (message == null) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
