import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_training_days_cycling_preview.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/steps/'
    'step_training_days_weekday_selector.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Details shown when a fixed training-day plan is selected.
class StepTrainingDaysDetails extends StatelessWidget {
  /// Creates fixed training-day details.
  const new({
    required this.state,
    required this.hasExtraKcal,
    required this.baseGoal,
    required this.onToggleWeekday,
    required this.onToggleExtraKcal,
    super.key,
  });

  /// Current calculator state.
  final CalorieGoalCalculatorFormState state;

  /// Whether extra training-day calories are enabled.
  final bool hasExtraKcal;

  /// Base calorie goal.
  final double baseGoal;

  /// Toggles one weekday.
  final ValueChanged<int> onToggleWeekday;

  /// Toggles extra calories.
  final ValueChanged<bool> onToggleExtraKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.onboardingTrainingDaysQuestion,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        StepTrainingDaysWeekdaySelector(
          selectedWeekdays: state.trainingWeekdays,
          onToggleWeekday: onToggleWeekday,
        ),
        const SizedBox(height: AppSpacing.md),
        AppSwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: hasExtraKcal,
          onChanged: onToggleExtraKcal,
          title: Text(
            l10n.onboardingTrainingDaysExtraKcalLabel,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            l10n.onboardingTrainingDaysExtraKcalSubtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        if (hasExtraKcal &&
            baseGoal > 0 &&
            state.trainingWeekdays.isNotEmpty &&
            state.trainingWeekdays.length < 7) ...[
          const SizedBox(height: AppSpacing.sm),
          StepTrainingDaysCyclingPreview(
            baseGoalKcal: baseGoal,
            trainingDaysCount: state.trainingWeekdays.length,
            offsetKcal: state.trainingDayKcalOffset,
          ),
        ],
      ],
    );
  }
}
