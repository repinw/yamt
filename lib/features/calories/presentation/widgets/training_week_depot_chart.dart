import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/training_week_goals.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One bar of [TrainingWeekDepotChart].
typedef TrainingWeekDepotDay = ({String label, bool isTraining});

/// Shows how the weekly calorie budget is spread over training and rest days.
///
/// The weekly sum holds the sessions; a training day gets one session more
/// than a rest day.
class TrainingWeekDepotChart extends StatelessWidget {
  /// Creates the week depot chart.
  const new({
    required this.days,
    required this.baseGoalKcal,
    required this.sessionKcal,
    required this.accent,
    super.key,
  });

  /// The seven days, in the order they are shown.
  final List<TrainingWeekDepotDay> days;

  /// Daily goal before calorie cycling.
  final double baseGoalKcal;

  /// kcal of one training session.
  final double sessionKcal;

  /// Color of the training day bars.
  final Color accent;

  int get _trainingDays => days.where((day) => day.isTraining).length;

  TrainingWeekGoals get _goals => resolveTrainingWeekGoals(
    baseGoalKcal: baseGoalKcal,
    trainingDays: _trainingDays,
    sessionKcal: sessionKcal,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final goals = _goals;
    final restRatio = goals.trainingDayKcal <= 0
        ? 1.0
        : goals.restDayKcal / goals.trainingDayKcal;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(
          alpha: AppIntroLayout.glassOpacity,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.introWeekDepotTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppIntroLayout.depotChartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: _DepotBar(
                        label: day.label,
                        heightFactor: day.isTraining
                            ? 1
                            : restRatio.clamp(0.25, 1.0),
                        isTraining: day.isTraining,
                        accent: accent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DepotLegend(
              trainingGoal: goals.trainingDayKcal,
              restGoal: goals.restDayKcal,
              trainingDays: _trainingDays,
              restDays: days.length - _trainingDays,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DepotBar extends StatelessWidget {
  const new({
    required this.label,
    required this.heightFactor,
    required this.isTraining,
    required this.accent,
  });

  final String label;
  final double heightFactor;
  final bool isTraining;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: heightFactor,
              child: AnimatedContainer(
                duration: AppIntroLayout.selectionTransition,
                decoration: BoxDecoration(
                  color: isTraining ? accent : colors.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepotLegend extends StatelessWidget {
  const new({
    required this.trainingGoal,
    required this.restGoal,
    required this.trainingDays,
    required this.restDays,
    required this.accent,
  });

  final double trainingGoal;
  final double restGoal;
  final int trainingDays;
  final int restDays;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (trainingDays > 0) ...[
          _LegendRow(
            color: accent,
            label: l10n.onboardingTrainingDaysTrainingResult(trainingDays),
            value: l10n.introSummaryKcalValue(trainingGoal.round()),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (restDays > 0)
          _LegendRow(
            color: colors.surfaceContainerHighest,
            label: l10n.onboardingTrainingDaysRestResult(restDays),
            value: l10n.introSummaryKcalValue(restGoal.round()),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const new({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: AppSpacing.xs,
          height: AppSpacing.xs,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
