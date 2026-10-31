import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_fade_in.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Right column of the budget card: protein, carbs, and fat, each with the
/// grams left (or over, or eaten) and a thin line. The macro with the
/// lowest share of its target takes its color, or every macro when the user
/// picked "Makros immer bunt"; over shows red only in the line.
class DiaryBudgetMacroColumn extends StatelessWidget {
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

  /// Whether the values show the grams eaten, plans counted, instead of the
  /// grams left.
  final bool showEaten;

  /// Locale number format.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final lowest = data.lowestMacro;
    // As the lowest macro: no color on a pause day or a past day.
    final allColored =
        MetricAccentColors.of(context).allMacrosColored &&
        !data.isPauseDay &&
        !data.status.isPast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBudgetCard.macroGap,
      children: [
        for (final macro in data.macros)
          _MacroRow(
            macro: macro,
            isColored: allColored || macro.kind == lowest,
            isPauseDay: data.isPauseDay,
            isPlannedDay: data.isPlannedDay,
            showDetails: showDetails,
            showEaten: showEaten,
            numberFormat: numberFormat,
          ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  const new({
    required this.macro,
    required this.isColored,
    required this.isPauseDay,
    required this.isPlannedDay,
    required this.showDetails,
    required this.showEaten,
    required this.numberFormat,
  });

  final DiaryBudgetMacro macro;
  final bool isColored;
  final bool isPauseDay;
  final bool isPlannedDay;
  final bool showDetails;
  final bool showEaten;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final accents = MetricAccentColors.of(context);
    final macroColor = _macroColor(accents);
    // Bright macro colors are darkened as text on light paper, unless the
    // user picked them.
    final macroText =
        Theme.of(context).brightness == Brightness.light &&
            !accents.macrosAsPicked
        ? _darkened(macroColor, AppFoodLabel.lightLabelMaxLightness)
        : macroColor;
    final counted = macro.eaten + macro.planned;
    final left = (macro.target - counted).round();
    String grams(num value) => numberFormat.format(value.round());

    final value = isPauseDay || showEaten
        ? l10n.diaryBudgetMacroLeft(grams(counted))
        : left < 0
        ? l10n.diaryBudgetMacroOver(grams(-left))
        : l10n.diaryBudgetMacroLeft(grams(left));
    // An overage keeps its text in ink; only its line shows red.
    final valueColor = isPauseDay
        ? colors.muted
        : isColored && left >= 0
        ? macroText
        : colors.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                _label(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.geist,
                  color: isColored ? macroText : colors.muted,
                ),
              ),
            ),
            DiaryBudgetCrossFade(
              value: value,
              alignment: AlignmentDirectional.topEnd,
              child: Text(
                value,
                key: DiaryBudgetCardKeys.macroValue(macro.kind),
                style: textTheme.titleLarge?.copyWith(
                  fontFamily: AppFonts.geist,
                  fontSize: AppBudgetCard.macroValue,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        DiaryBudgetLine(
          eaten: macro.eaten,
          planned: macro.planned,
          target: isPauseDay ? null : macro.target,
          scaleKcal: macro.target,
          compact: true,
          eatenColor: isPauseDay
              ? colors.muted
              : isPlannedDay
              ? colors.plan
              : isColored
              ? macroColor
              : null,
        ),
        if (showDetails)
          DiaryBudgetFadeIn(
            child: DiaryBudgetCrossFade(
              value: (macro.eaten.round(), macro.planned.round()),
              child: _MacroDetails(
                macro: macro,
                isPauseDay: isPauseDay,
                numberFormat: numberFormat,
              ),
            ),
          ),
      ],
    );
  }

  String _label(AppLocalizations l10n) => switch (macro.kind) {
    DiaryBudgetMacroKind.protein => l10n.caloriesProteinLabel,
    DiaryBudgetMacroKind.carbs => l10n.diaryBudgetCarbsLabel,
    DiaryBudgetMacroKind.fat => l10n.caloriesFatLabel,
  };

  Color _macroColor(MetricAccentColors accents) => switch (macro.kind) {
    DiaryBudgetMacroKind.protein => accents.protein,
    DiaryBudgetMacroKind.carbs => accents.carbs,
    DiaryBudgetMacroKind.fat => accents.fat,
  };
}

/// Eaten of target grams of [macro], and its counted plans; the eaten grams
/// alone on a pause day.
class _MacroDetails extends StatelessWidget {
  const new({
    required this.macro,
    required this.isPauseDay,
    required this.numberFormat,
  });

  final DiaryBudgetMacro macro;
  final bool isPauseDay;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: AppFonts.geist, color: colors.muted);
    String grams(num value) => numberFormat.format(value.round());

    return Text.rich(
      key: DiaryBudgetCardKeys.macroTotal(macro.kind),
      TextSpan(
        text: isPauseDay
            ? l10n.diaryBudgetMacroEaten(grams(macro.eaten))
            : l10n.diaryMacroEatenOfTarget(
                grams(macro.eaten + macro.planned),
                grams(macro.target),
              ),
        children: [
          if (macro.planned.round() > 0)
            TextSpan(
              text: '\n${l10n.diaryBudgetMacroPlanned(grams(macro.planned))}',
              style: style?.copyWith(color: colors.plan),
            ),
        ],
      ),
      style: style,
    );
  }
}

/// [color] with its HSL lightness capped at [maxLightness].
Color _darkened(Color color, double maxLightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness(math.min(hsl.lightness, maxLightness)).toColor();
}
