import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_selectable_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/onboarding_step_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_training_days_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Onboarding step to configure training days and calorie cycling offset.
class StepTrainingDays extends StatelessWidget {
  /// Creates training days onboarding step.
  const StepTrainingDays({
    required this.state,
    required this.notifier,
    super.key,
  });

  /// Current calculator form state.
  final CalorieGoalCalculatorFormState state;

  /// Calculator form notifier.
  final CalorieGoalCalculatorFormController notifier;

  static const _defaultExtraKcal = 200.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFixedDays = state.trainingWeekdays.isNotEmpty;
    final hasExtraKcal = state.trainingDayKcalOffset > 0;
    final baseGoal = state.calculation?.finalGoalKcal ?? 0.0;

    return OnboardingStepContent(
      title: l10n.onboardingTrainingDaysTitle,
      subtitle: l10n.onboardingTrainingDaysSubtitle,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _TrainingChoiceCard(
          title: l10n.onboardingTrainingDaysNoFixedPlan,
          subtitle: l10n.onboardingTrainingDaysNoFixedPlanSubtitle,
          icon: Icons.calendar_today_outlined,
          isSelected: !hasFixedDays,
          onTap: () {
            notifier
              ..updateTrainingWeekdays(const <int>[])
              ..updateTrainingDayKcalOffset(0);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _TrainingChoiceCard(
          title: l10n.onboardingTrainingDaysFixedPlan,
          subtitle: l10n.onboardingTrainingDaysFixedPlanSubtitle,
          icon: Icons.fitness_center_rounded,
          isSelected: hasFixedDays,
          onTap: () {
            if (!hasFixedDays) {
              notifier
                ..updateTrainingWeekdays(const <int>[1, 3, 5])
                ..updateTrainingDayKcalOffset(_defaultExtraKcal);
            }
          },
          child: hasFixedDays
              ? StepTrainingDaysDetails(
                  state: state,
                  hasExtraKcal: hasExtraKcal,
                  baseGoal: baseGoal,
                  onToggleWeekday: _toggleWeekday,
                  onToggleExtraKcal: (enabled) {
                    notifier.updateTrainingDayKcalOffset(
                      enabled ? _defaultExtraKcal : 0.0,
                    );
                  },
                )
              : null,
        ),
      ],
    );
  }

  void _toggleWeekday(int weekday) {
    final next = List<int>.from(state.trainingWeekdays);
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next
        ..add(weekday)
        ..sort();
    }
    if (next.isEmpty) {
      notifier
        ..updateTrainingWeekdays(const <int>[])
        ..updateTrainingDayKcalOffset(0);
      return;
    }
    notifier.updateTrainingWeekdays(next);
  }
}

class _TrainingChoiceCard extends StatelessWidget {
  const _TrainingChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return OnboardingSelectableCard(
      isSelected: isSelected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? colors.primary : colors.outline,
                size: 20,
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: AppSpacing.md),
            child!,
          ],
        ],
      ),
    );
  }
}
