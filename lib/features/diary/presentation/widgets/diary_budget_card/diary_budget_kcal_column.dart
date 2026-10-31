import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_fade_in.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_kcal_texts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Left column of the budget card: the kcal left (or eaten) as a big
/// number, what it means, and the kcal line, which can mark where the day
/// should be by now. Over the target it shows the overage in the error
/// color; a pause day shows its word instead.
class DiaryBudgetKcalColumn extends StatelessWidget {
  /// Creates the column.
  const new({
    required this.data,
    required this.showDetails,
    required this.showEaten,
    required this.numberFormat,
    super.key,
  });

  /// Card data.
  final DiaryBudgetCardData data;

  /// Whether the details are open.
  final bool showDetails;

  /// Whether the big number shows the kcal eaten, plans counted, instead of
  /// the kcal left. A pause day always shows what was eaten.
  final bool showEaten;

  /// Locale number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final metrics = data.metrics;
    final (:unitStyle, :subStyle) = _styles(context);
    String kcal(double value) => numberFormat.format(value.round());
    // Going over is the miss for every weight goal but gaining.
    final overColor = data.overIsMiss
        ? Theme.of(context).colorScheme.error
        : colors.ink;

    if (data.isPauseDay) {
      return _PauseKcal(data: data, numberFormat: numberFormat);
    }

    final counted = metrics.eatenKcal + data.countedPlannedKcal;
    final (:value, :unit, :color, :amount) = diaryBudgetKcalTexts(
      context,
      data: data,
      showEaten: showEaten,
      numberFormat: numberFormat,
    );
    final plannedKcal = kcal(data.countedPlannedKcal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xxs,
      children: [
        DiaryBudgetCrossFade(
          value: value,
          child: _BigText(
            value,
            size: amount.round().abs() >= 1000
                ? AppBudgetCard.bigNumberLong
                : AppBudgetCard.bigNumber,
            color: color,
          ),
        ),
        DiaryBudgetCrossFade(
          value: unit,
          child: Text(
            unit,
            key: DiaryBudgetCardKeys.kcalUnit,
            style: unitStyle,
          ),
        ),
        // With the details open the goal and what the week adds to it.
        if (showDetails && metrics.carryoverKcal.round() != 0)
          DiaryBudgetFadeIn(
            child: _CarryoverChip(
              goalKcal: metrics.targetKcal - metrics.carryoverKcal,
              carryoverKcal: metrics.carryoverKcal,
              numberFormat: numberFormat,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        DiaryBudgetLine(
          eaten: metrics.eatenKcal,
          planned: data.countedPlannedKcal,
          target: metrics.targetKcal,
          // On a planned day all of the day is a plan; else the eaten kcal
          // take the user's accent.
          eatenColor: data.isPlannedDay ? colors.plan : colors.accent,
          pace: data.paceKcal,
          overColor: overColor,
        ),
        // The eaten view already shows eaten of target.
        if (showDetails && !showEaten)
          DiaryBudgetFadeIn(
            child: DiaryBudgetCrossFade(
              value: (counted.round(), data.countedPlannedKcal.round()),
              child: Text.rich(
                key: DiaryBudgetCardKeys.kcalTotal,
                TextSpan(
                  text: l10n.diaryBudgetKcalEatenOfTarget(
                    kcal(counted),
                    kcal(metrics.targetKcal),
                  ),
                  children: [
                    if (data.countedPlannedKcal.round() > 0)
                      TextSpan(
                        text: '\n${l10n.diaryBudgetMacroPlanned(plannedKcal)}',
                        style: subStyle?.copyWith(color: colors.plan),
                      ),
                  ],
                ),
                style: subStyle,
              ),
            ),
          ),
      ],
    );
  }
}

/// The goal and the carryover that the week adds to it or takes from it, as
/// "2.200 − 125 aus der Woche".
class _CarryoverChip extends StatelessWidget {
  const new({
    required this.goalKcal,
    required this.carryoverKcal,
    required this.numberFormat,
  });

  final double goalKcal;
  final double carryoverKcal;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final goal = numberFormat.format(goalKcal.round());
    final carryover = numberFormat.format(carryoverKcal.abs().round());
    final isLess = carryoverKcal < 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          isLess
              ? l10n.diaryBudgetCarryoverChipLess(goal, carryover)
              : l10n.diaryBudgetCarryoverChipMore(goal, carryover),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFamily: AppFonts.geist,
            fontWeight: FontWeight.w600,
            color: isLess ? colors.ink : colors.accentText,
          ),
        ),
      ),
    );
  }
}

/// The kcal column of a pause day: its word in grey, what was eaten and
/// planned, and that the day is ignored.
class _PauseKcal extends StatelessWidget {
  const new({required this.data, required this.numberFormat});

  final DiaryBudgetCardData data;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final metrics = data.metrics;
    final (:unitStyle, :subStyle) = _styles(context);
    String kcal(double value) => numberFormat.format(value.round());

    final planned = data.countedPlannedKcal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xxs,
      children: [
        _BigText(
          l10n.diaryBalancePauseDayValue,
          size: AppBudgetCard.bigWord,
          color: colors.muted,
        ),
        Text.rich(
          key: DiaryBudgetCardKeys.kcalUnit,
          TextSpan(
            text: l10n.diaryBudgetPauseEaten(kcal(metrics.realEatenKcal)),
            children: [
              if (planned > 0)
                TextSpan(
                  text: ' ${l10n.diaryBudgetPausePlanned(kcal(planned))}',
                  style: unitStyle?.copyWith(color: colors.plan),
                ),
            ],
          ),
          style: unitStyle,
        ),
        Text(l10n.diaryBalancePauseDaySubtitle, style: subStyle),
        const SizedBox(height: AppSpacing.xs),
        DiaryBudgetLine(
          eaten: metrics.realEatenKcal,
          planned: planned,
          target: null,
          scaleKcal: metrics.targetKcal,
          eatenColor: colors.muted,
        ),
      ],
    );
  }
}

/// The unit line under the big number and the smaller lines under it.
({TextStyle? unitStyle, TextStyle? subStyle}) _styles(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  final muted = FoodLabelColors.of(context).muted;
  return (
    unitStyle: textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.geist,
      fontWeight: FontWeight.w500,
      color: muted,
    ),
    subStyle: textTheme.bodySmall?.copyWith(
      fontFamily: AppFonts.geist,
      color: muted,
    ),
  );
}

/// The big number or word, shrunk to fit its column.
class _BigText extends StatelessWidget {
  const new(this.text, {required this.size, required this.color});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        key: DiaryBudgetCardKeys.kcalValue,
        maxLines: 1,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontFamily: AppFonts.geist,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: AppBudgetCard.bigNumberLineHeight,
          letterSpacing: size * AppBudgetCard.bigNumberTracking,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
