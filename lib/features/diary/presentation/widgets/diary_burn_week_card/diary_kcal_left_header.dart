import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the daily balance: what is left as a big number, and with
/// details what was eaten out of which target.
///
/// Over the target it shows the overage, planned days show the planned
/// kcal and the target, and pause days show a word. A planned pause day shows
/// the planned kcal and the pause word instead of the target.
class DiaryKcalLeftHeader extends StatelessWidget {
  /// Creates the head.
  const new({required this.data, required this.showDetails, super.key});

  /// Render-ready card data.
  final DiaryDailyBalanceData data;

  /// Whether eaten and target are shown next to the number.
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;
    final accent = data.isOverTarget
        ? error
        : data.isPauseDay
        ? colors.muted
        : data.isPlanned
        ? colors.ink
        : colors.accentText;
    final label = data.isPlanned
        ? l10n.diaryBalancePlannedLabel
        : data.isOverTarget
        ? l10n.diaryBalanceOverGoalLabel
        : data.leftLabel;
    final value = data.isPlanned ? data.eatenValue : data.leftValue;
    final unit = data.isPlanned ? data.caloriesUnit : data.leftUnit;
    final mono = textTheme.labelMedium?.copyWith(fontFamily: AppFonts.mono);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                key: DiaryBalanceCardKeys.kcalHeadLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: data.isOverTarget ? error : colors.muted,
                  letterSpacing: AppFoodLabel.brandTracking,
                ),
              ),
            ),
            // Shows that a tap opens or closes the details.
            AnimatedRotation(
              turns: showDetails ? 0.5 : 0,
              duration: AppDurations.compactMetricExpansion,
              child: Icon(Icons.expand_more_rounded, color: colors.ink),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      value,
                      key: DiaryBalanceCardKeys.kcalHeadValue,
                      maxLines: 1,
                      style: textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                        height: 1,
                      ),
                    ),
                    if (unit != null)
                      Text(unit, style: mono?.copyWith(color: accent)),
                  ],
                ),
              ),
            ),
            // A planned day always names its goal: the big number alone
            // does not say how much is left to plan.
            if (data.isPlanned || (showDetails && !data.isPauseDay))
              _EatenOfTarget(data: data, style: mono),
          ],
        ),
      ],
    );
  }
}

/// "X eaten" over "of Y", or only "of Y" (the pause word on a pause day) on
/// planned days.
class _EatenOfTarget extends StatelessWidget {
  const new({required this.data, required this.style});

  final DiaryDailyBalanceData data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final eatenSubtitle = data.eatenSubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (data.isPlanned)
          Text(
            data.isPauseDay
                ? l10n.diaryBalancePauseDayValue
                : l10n.diaryBalanceOfTarget(data.targetNumber),
            key: DiaryBalanceCardKeys.kcalHeadTarget,
            style: style?.copyWith(color: colors.muted),
          )
        else ...[
          Text(
            l10n.diaryBalanceEatenAmount(data.eatenValue),
            style: style?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.diaryBalanceOfTarget(data.targetNumber),
            style: style?.copyWith(color: colors.muted),
          ),
          if (eatenSubtitle != null)
            Text(eatenSubtitle, style: style?.copyWith(color: colors.muted)),
        ],
      ],
    );
  }
}
