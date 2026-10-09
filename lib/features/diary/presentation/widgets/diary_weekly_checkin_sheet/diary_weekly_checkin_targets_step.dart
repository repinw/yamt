import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_labels.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_facts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Step 3: the daily targets of the next run.
class DiaryWeeklyCheckInTargetsStep extends StatelessWidget {
  /// Creates the targets step.
  const new({
    required this.targets,
    required this.trainingDayCount,
    required this.restDayCount,
    required this.format,
    super.key,
  });

  /// Targets of the next run.
  final CalorieWeeklyCheckInTargets targets;

  /// Planned training days.
  final int trainingDayCount;

  /// Planned rest days.
  final int restDayCount;

  /// Number formats.
  final DiaryWeeklyCheckInNumberFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = FoodLabelColors.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: colors.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.diaryCheckInAverageGoal.toUpperCase(),
          style: context.graphitKickerStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: format.kcal(targets.goalKcal),
                  children: [
                    TextSpan(
                      text: ' ${l10n.caloriesUnitKcal}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
                style: context.graphitDisplayStyle(
                  theme.textTheme.displayMedium,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  targets.isMeasured
                      ? l10n.diaryCheckInMeasuredSource
                      : l10n.diaryCheckInPreviousSource,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.diaryCheckInGoalChange(
                    format.signedKcal(targets.goalChangeKcal),
                  ),
                  style: muted,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DiaryWeeklyCheckInFacts(
          facts: [
            _dayFact(l10n, DiaryDayType.training, trainingDayCount, targets),
            _dayFact(l10n, DiaryDayType.rest, restDayCount, targets),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _MacroTable(targets: targets),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.diaryCheckInMacroWeightDetail(format.kg(targets.macroWeightKg)),
          style: muted,
        ),
      ],
    );
  }

  DiaryWeeklyCheckInFact _dayFact(
    AppLocalizations l10n,
    DiaryDayType type,
    int count,
    CalorieWeeklyCheckInTargets targets,
  ) {
    final kcal = type == DiaryDayType.training
        ? targets.trainingDayKcal
        : targets.restDayKcal;
    return (
      kicker:
          '${diaryDayTypeEmoji(type)} ${diaryDayTypeShortLabel(type, l10n)}',
      value: format.kcal(kcal),
      unit: null,
      caption: l10n.diaryCheckInDayCount(count),
    );
  }
}

class _MacroTable extends StatelessWidget {
  const new({required this.targets});

  final CalorieWeeklyCheckInTargets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final theme = Theme.of(context);
    final header = context.graphitKickerStyle;
    final value = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final rows = [
      (
        l10n.caloriesProteinLabel,
        targets.previousMacros.protein,
        targets.macros.protein,
      ),
      (l10n.caloriesFatLabel, targets.previousMacros.fat, targets.macros.fat),
      (
        l10n.caloriesCarbsLabel,
        targets.previousMacros.carbs,
        targets.macros.carbs,
      ),
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(2)},
      border: TableBorder(
        top: BorderSide(color: colors.ink, width: 2),
        horizontalInside: BorderSide(color: colors.rule),
        bottom: BorderSide(color: colors.rule),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            _Cell(l10n.diaryCheckInMacros.toUpperCase(), style: header),
            _Cell(
              l10n.diaryCheckInMacrosPrevious.toUpperCase(),
              style: header,
              end: true,
            ),
            _Cell(
              l10n.diaryCheckInMacrosNew.toUpperCase(),
              style: header,
              end: true,
            ),
          ],
        ),
        for (final (label, before, after) in rows)
          TableRow(
            children: [
              _Cell(label, style: theme.textTheme.bodyMedium),
              _Cell(
                l10n.diaryCheckInGramsValue(before.round()),
                style: value?.copyWith(color: colors.muted),
                end: true,
              ),
              _Cell(
                l10n.diaryCheckInGramsValue(after.round()),
                style: value,
                end: true,
              ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const new(this.text, {required this.style, this.end = false});

  final String text;
  final TextStyle? style;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: style,
        textAlign: end ? TextAlign.end : TextAlign.start,
      ),
    );
  }
}
