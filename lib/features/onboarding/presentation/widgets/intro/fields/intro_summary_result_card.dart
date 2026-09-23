import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/onboarding/domain/training_week_goals.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the calculated expenditure and the resulting daily intake target.
///
/// With training days it also shows the target of a training day and of a
/// rest day.
class IntroSummaryResultCard extends StatelessWidget {
  /// Creates the summary result card.
  const new({
    required this.calculation,
    required this.trainingWeekdays,
    required this.trainingDayKcalOffset,
    super.key,
  });

  /// Result of the calorie goal calculation.
  final CalorieGoalCalculationResult calculation;

  /// Weekdays that carry a workout, 1 = Monday.
  final List<int> trainingWeekdays;

  /// Extra calories granted on a training day.
  final double trainingDayKcalOffset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final difference = (calculation.finalGoalKcal - calculation.tdeeKcal)
        .round();
    final trainingDays = trainingWeekdays.length;
    final restDays = DateTime.daysPerWeek - trainingDays;
    final weekGoals = resolveTrainingWeekGoals(
      baseGoalKcal: calculation.finalGoalKcal,
      trainingDays: trainingDays,
      offsetKcal: trainingDayKcalOffset,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(
          alpha: AppIntroLayout.glassOpacity,
        ),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: AppIntroLayout.controlBorderOpacity,
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultRow(
              icon: Icons.local_fire_department_outlined,
              label: l10n.introSummaryExpenditureLabel,
              value: l10n.introSummaryKcalValue(calculation.tdeeKcal.round()),
              hint: l10n.introSummaryExpenditureHint,
              emphasized: false,
            ),
            const Divider(height: AppSpacing.xxl),
            _ResultRow(
              icon: Icons.flag_outlined,
              label: l10n.introSummaryTargetLabel,
              value: l10n.introSummaryKcalValue(
                calculation.finalGoalKcal.round(),
              ),
              hint: _targetHint(l10n, difference),
              emphasized: true,
            ),
            if (trainingDays > 0 && restDays > 0) ...[
              const Divider(height: AppSpacing.xxl),
              _ResultRow(
                icon: Icons.fitness_center_rounded,
                label: l10n.onboardingTrainingDaysTrainingResult(trainingDays),
                value: l10n.introSummaryKcalValue(
                  weekGoals.trainingDayKcal.round(),
                ),
                emphasized: false,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ResultRow(
                icon: Icons.weekend_outlined,
                label: l10n.onboardingTrainingDaysRestResult(restDays),
                value: l10n.introSummaryKcalValue(
                  weekGoals.restDayKcal.round(),
                ),
                hint: l10n.introSummaryDepotHint,
                emphasized: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// [difference] is the daily target minus the expenditure, so it is negative
  /// for a deficit and positive for a surplus.
  String _targetHint(AppLocalizations l10n, int difference) {
    if (difference < 0) {
      return l10n.introSummaryTargetDeficitHint(-difference);
    }
    if (difference > 0) {
      return l10n.introSummaryTargetSurplusHint(difference);
    }
    return l10n.introSummaryTargetMaintainHint;
  }
}

class _ResultRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    required this.emphasized,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final valueColor = emphasized ? colors.primary : colors.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: emphasized ? colors.primary : colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              if (hint case final hint?) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style:
              (emphasized
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
