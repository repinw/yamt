import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Protein, carbohydrates and fat in whole grams, in this order. Only the
/// numbers carry the fixed macro colors; labels and dots are muted, with no
/// pills, backgrounds or icons. A screen reader reads one sentence.
class MacroGrams extends StatelessWidget {
  /// Three equal columns, "15 g" over "Eiweiß", for cards and pages with
  /// room; [centered] centers each column.
  const new columns({
    required this.protein,
    required this.carbs,
    required this.fat,
    this.palette,
    this.centered = false,
    super.key,
  }) : _isLine = false;

  /// One line "P 14 · KH 51 · F 14" for tight places such as a grid card.
  const new line({
    required this.protein,
    required this.carbs,
    required this.fat,
    super.key,
  }) : palette = null,
       centered = false,
       _isLine = true;

  /// Protein in grams.
  final num protein;

  /// Carbohydrates in grams.
  final num carbs;

  /// Fat in grams.
  final num fat;

  /// The colors to draw on, such as the dark ones over a photo; the theme's
  /// when `null`.
  final FoodLabelColors? palette;

  /// Whether each column centers its number and label.
  final bool centered;

  final bool _isLine;

  /// The fixed colors of protein, carbohydrates and fat for numbers on
  /// [palette] (the theme's when `null`): as the cook picked them, else
  /// darkened on light paper and lightened on dark paper, so they read.
  static ({Color protein, Color carbs, Color fat}) textColors(
    BuildContext context, {
    FoodLabelColors? palette,
  }) {
    final paper = (palette ?? FoodLabelColors.of(context)).paper;
    final accents = MetricAccentColors.of(context);
    final lightPaper =
        ThemeData.estimateBrightnessForColor(paper) == Brightness.light;
    Color tone(Color macro) => accents.macrosAsPicked
        ? macro
        : _readable(macro, lightPaper: lightPaper);
    return (
      protein: tone(accents.protein),
      carbs: tone(accents.carbs),
      fat: tone(accents.fat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = palette ?? FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final tones = textColors(context, palette: colors);
    final macros = [
      (protein.round(), tones.protein),
      (carbs.round(), tones.carbs),
      (fat.round(), tones.fat),
    ];
    return Semantics(
      label: l10n.macroGramsSemanticLabel(
        macros[0].$1,
        macros[1].$1,
        macros[2].$1,
      ),
      child: ExcludeSemantics(
        child: _isLine
            ? _Line(
                macros: macros,
                letters: [
                  l10n.caloriesProteinShortLetter,
                  l10n.macroGramsCarbsShort,
                  l10n.caloriesFatShortLetter,
                ],
                number: number,
                style: textTheme.labelSmall!.copyWith(
                  color: colors.muted,
                  fontFamily: AppFonts.mono,
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  for (final ((grams, color), label) in [
                    (macros[0], l10n.caloriesProteinLabel),
                    (macros[1], l10n.caloriesCarbsLabel),
                    (macros[2], l10n.caloriesFatLabel),
                  ])
                    Expanded(
                      child: Column(
                        crossAxisAlignment: centered
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            // No-break space: number and unit stay together.
                            '${number.format(grams)} '
                            '${l10n.caloriesUnitGram}',
                            style: textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // A long label such as "Kohlenhydrate" shrinks
                          // at large text instead of being cut off.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: centered
                                ? Alignment.center
                                : AlignmentDirectional.centerStart,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// "P 14 · KH 51 · F 14": [letters] and dots in the muted [style], each
// number in its color; one line that keeps its height.
class _Line extends StatelessWidget {
  const new({
    required this.macros,
    required this.letters,
    required this.number,
    required this.style,
  });

  final List<(int, Color)> macros;
  final List<String> letters;
  final NumberFormat number;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final (index, (grams, color)) in macros.indexed) ...[
          if (index > 0) const TextSpan(text: _dot),
          TextSpan(text: '${letters[index]} '),
          TextSpan(
            text: number.format(grams),
            style: style.copyWith(color: color),
          ),
        ],
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: style,
    strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
  );
}

const _dot = ' · ';

// [macro] as text: darkened on light paper, lightened on dark paper.
Color _readable(Color macro, {required bool lightPaper}) {
  final hsl = HSLColor.fromColor(macro);
  final lightness = lightPaper
      ? math.min(hsl.lightness, AppFoodLabel.lightLabelMaxLightness)
      : math.max(hsl.lightness, AppFoodLabel.darkLabelMinLightness);
  return hsl.withLightness(lightness).toColor();
}
