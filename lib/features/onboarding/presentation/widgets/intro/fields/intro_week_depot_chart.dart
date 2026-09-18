import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Any Monday, used to render localized weekday initials.
final _referenceMonday = DateTime(2024);

/// Shows how the weekly calorie budget is spread over training and rest days.
///
/// The weekly sum stays the same; training days borrow from the rest days.
class IntroWeekDepotChart extends StatelessWidget {
  /// Creates the week depot chart.
  const new({
    required this.baseGoalKcal,
    required this.trainingWeekdays,
    required this.offsetKcal,
    required this.accent,
    super.key,
  });

  /// Daily goal before calorie cycling.
  final double baseGoalKcal;

  /// Weekdays that carry a workout, 1 = Monday.
  final List<int> trainingWeekdays;

  /// Extra calories granted on a training day.
  final double offsetKcal;

  /// Accent color of this chapter.
  final Color accent;

  int get _trainingDays => trainingWeekdays.length;

  int get _restDays => DateTime.daysPerWeek - _trainingDays;

  /// Cycling only shifts calories when there are both kinds of days.
  double get _effectiveOffset =>
      _trainingDays == 0 || _restDays == 0 ? 0 : offsetKcal;

  double get _trainingGoal => baseGoalKcal + _effectiveOffset;

  double get _restGoal => _restDays == 0
      ? baseGoalKcal
      : baseGoalKcal - (_trainingDays * _effectiveOffset) / _restDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayFormat = DateFormat.E(locale);
    final restRatio = _trainingGoal <= 0 ? 1.0 : _restGoal / _trainingGoal;

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
                  for (
                    var weekday = 1;
                    weekday <= DateTime.daysPerWeek;
                    weekday++
                  )
                    Expanded(
                      child: _DepotBar(
                        label: weekdayFormat.format(
                          _referenceMonday.add(Duration(days: weekday - 1)),
                        ),
                        heightFactor: trainingWeekdays.contains(weekday)
                            ? 1
                            : restRatio.clamp(0.25, 1.0),
                        isTraining: trainingWeekdays.contains(weekday),
                        accent: accent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DepotLegend(
              trainingGoal: _trainingGoal,
              restGoal: _restGoal,
              trainingDays: _trainingDays,
              restDays: _restDays,
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
