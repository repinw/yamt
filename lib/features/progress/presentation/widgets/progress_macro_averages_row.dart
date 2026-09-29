import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/progress/domain/progress_average.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Average protein, carbohydrates and fat per day, each against its goal.
class ProgressMacroAveragesRow extends StatelessWidget {
  /// Creates the macro averages row.
  const new({required this.average, super.key});

  /// The averages to show.
  final ProgressAverage average;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final macros = MetricAccentColors.of(context);
    final rule = FoodLabelColors.of(context).rule;
    final cells = [
      (
        macros.protein,
        l10n.caloriesProteinLabel,
        average.proteinGrams,
        average.proteinGoalGrams,
      ),
      (
        macros.carbs,
        l10n.caloriesCarbsShortLabel,
        average.carbsGrams,
        average.carbsGoalGrams,
      ),
      (
        macros.fat,
        l10n.caloriesFatLabel,
        average.fatGrams,
        average.fatGoalGrams,
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (final (index, cell) in cells.indexed) ...[
                if (index > 0)
                  VerticalDivider(width: AppSpacing.xxl, color: rule),
                Expanded(
                  child: _MacroCell(
                    color: cell.$1,
                    label: cell.$2,
                    grams: cell.$3,
                    goalGrams: cell.$4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const new({
    required this.color,
    required this.label,
    required this.grams,
    required this.goalGrams,
  });

  final Color color;
  final String label;
  final double grams;
  final double goalGrams;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final small = textTheme.labelSmall?.copyWith(color: colors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: AppProgress.legendSwatch,
              child: ColoredBox(color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(label, style: small)),
          ],
        ),
        Text(
          l10n.progressGrams(number.format(grams.round())),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        Text(
          l10n.progressMacroGoal(number.format(goalGrams.round())),
          style: small,
        ),
      ],
    );
  }
}
