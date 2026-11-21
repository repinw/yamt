import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/utils/text_measure.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_fade_in.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_details.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final largeText = isLargeText(context);
    // Measured only at large text, the one case that needs it.
    double widest(Iterable<String> texts, TextStyle? style) => largeText
        ? texts
              .map((text) => measureTextWidth(context, text, style))
              .fold<double>(0, math.max)
        : 0;

    // The three rows take the same form: names and grams side by side, or,
    // at large text where the longest of each does not fit one line, the
    // grams under the name.
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueWidth = widest([
          for (final macro in data.macros)
            diaryBudgetMacroValue(
              l10n,
              macro,
              showEaten: showEaten,
              isPauseDay: data.isPauseDay,
              numberFormat: numberFormat,
            ),
        ], _valueStyle(context));
        final nameWidth = widest([
          for (final macro in data.macros)
            diaryBudgetMacroLabel(l10n, macro.kind),
        ], _nameStyle(context));
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
                stacked:
                    largeText && nameWidth + valueWidth > constraints.maxWidth,
                valueWidth: valueWidth,
              ),
          ],
        );
      },
    );
  }
}

TextStyle? _nameStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontFamily: AppFonts.geist);

TextStyle? _valueStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge?.copyWith(
      fontFamily: AppFonts.geist,
      fontSize: AppBudgetCard.macroValue,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class _MacroRow extends StatelessWidget {
  const new({
    required this.macro,
    required this.isColored,
    required this.isPauseDay,
    required this.isPlannedDay,
    required this.showDetails,
    required this.showEaten,
    required this.numberFormat,
    required this.stacked,
    required this.valueWidth,
  });

  final DiaryBudgetMacro macro;
  final bool isColored;
  final bool isPauseDay;
  final bool isPlannedDay;
  final bool showDetails;
  final bool showEaten;
  final NumberFormat numberFormat;

  /// Whether the grams sit under the name.
  final bool stacked;

  /// Width of the widest of the three values; they share one size.
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final macroColor = diaryBudgetMacroColor(context, macro.kind);
    final macroText = diaryBudgetMacroTextColor(context, macroColor);
    final label = diaryBudgetMacroLabel(l10n, macro.kind);
    final nameStyle = _nameStyle(context)
        ?.copyWith(color: isColored ? macroText : colors.muted);
    final left = (macro.target - macro.eaten - macro.planned).round();
    final value = diaryBudgetMacroValue(
      l10n,
      macro,
      showEaten: showEaten,
      isPauseDay: isPauseDay,
      numberFormat: numberFormat,
    );
    // An overage keeps its text in ink; only its line shows red.
    final valueColor = isPauseDay
        ? colors.muted
        : isColored && left >= 0
        ? macroText
        : colors.ink;

    final valueStyle = _valueStyle(context)?.copyWith(color: valueColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        _NameAndValue(
          stacked: stacked,
          valueWidth: valueWidth,
          name: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
          value: DiaryBudgetCrossFade(
            value: value,
            alignment: AlignmentDirectional.topEnd,
            child: Text(
              value,
              key: DiaryBudgetCardKeys.macroValue(macro.kind),
              style: valueStyle,
              maxLines: 1,
              softWrap: false,
            ),
          ),
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
              child: DiaryBudgetMacroDetails(
                macro: macro,
                isPauseDay: isPauseDay,
                numberFormat: numberFormat,
              ),
            ),
          ),
      ],
    );
  }
}

/// A macro's name with its grams on the right, or, when [stacked], the
/// grams below the name, shrunk with the other rows to the room they share.
class _NameAndValue extends StatelessWidget {
  const new({
    required this.stacked,
    required this.valueWidth,
    required this.name,
    required this.value,
  });

  final bool stacked;
  final double valueWidth;
  final Widget name;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    if (!stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: name),
          value,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        name,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: valueWidth,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: value,
            ),
          ),
        ),
      ],
    );
  }
}
