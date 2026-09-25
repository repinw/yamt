import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_animated_macro_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Single macronutrient row: label in the macro color, a bar of four equal
/// segments, and the grams left, or over, as a big number.
///
/// Eating beyond the target stripes the end of the bar. With totals, the
/// eaten and target grams sit under the number.
class DiaryNutritionMacroRow extends StatelessWidget {
  /// Creates a nutrition macro row.
  const new({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.numberFormat,
    this.showTotal = true,
    super.key,
  });

  /// Macro display label (e.g. Protein, KH, Fett).
  final String label;

  /// Consumed amount in grams.
  final double current;

  /// Target amount in grams.
  final double target;

  /// Distinctive accent color for this macronutrient.
  final Color color;

  /// Localized number formatter.
  final NumberFormat numberFormat;

  /// Whether eaten and target grams are shown under the number.
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;
    final remaining = target - current;
    final isOverTarget = remaining < -0.5;
    final amount = numberFormat.format(
      isOverTarget ? -remaining.round() : math.max(0, remaining.round()),
    );
    final valueColor = isOverTarget ? error : colors.ink;
    final mono = textTheme.labelSmall?.copyWith(fontFamily: AppFonts.mono);
    final labelColor = Theme.of(context).brightness == Brightness.light
        ? _darkened(color, AppFoodLabel.lightLabelMaxLightness)
        : color;

    return Row(
      spacing: AppSpacing.md,
      children: [
        SizedBox(
          width: AppFoodLabel.macroLabelColumn,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          child: DiaryAnimatedMacroBar(
            handoffTag: (#diaryMacroBar, label),
            current: current,
            target: target,
            color: color,
            trackColor: colors.rule,
            overflowColor: error,
            height: AppFoodLabel.macroBar,
          ),
        ),
        SizedBox(
          width: AppFoodLabel.macroValueColumn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: AppSpacing.xxs,
                  children: [
                    Text(
                      isOverTarget ? '+$amount' : amount,
                      style: textTheme.titleLarge?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
                    ),
                    Text(
                      isOverTarget
                          ? l10n.diaryMacroOverSuffix
                          : l10n.diaryMacroLeftSuffix,
                      style: mono?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTotal)
                Text(
                  l10n.diaryMacroEatenOfTarget(
                    numberFormat.format(current.round()),
                    numberFormat.format(target.round()),
                  ),
                  maxLines: 1,
                  style: mono?.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [color] with its HSL lightness capped at [maxLightness].
Color _darkened(Color color, double maxLightness) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness(math.min(hsl.lightness, maxLightness)).toColor();
}
