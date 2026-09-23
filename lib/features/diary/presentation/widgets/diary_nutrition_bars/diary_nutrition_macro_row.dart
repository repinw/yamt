import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_color_roles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_animated_macro_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_scaled_value_text.dart';

const double _valueWidth = 42;
const double _totalWidth = 68;

/// Width of the value column of a quiet macro row.
const double diaryQuietMacroValueWidth = 60;

/// Gap between a macro row's value and label columns.
const double diaryMacroValueLabelGap = 6;

/// Width of a macro row's label column.
const double diaryMacroLabelWidth = 44;

/// Single macronutrient progress row with remaining value, label,
/// segmented bar, and optionally the consumed/target ratio.
///
/// Eating beyond the target stripes the end of the bar.
class DiaryNutritionMacroRow extends StatelessWidget {
  /// Creates a nutrition macro row.
  const new({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.numberFormat,
    required this.unit,
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

  /// Display unit string (e.g. "g").
  final String unit;

  /// Whether the consumed/target ratio is shown after the bar.
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final remaining = target - current;
    final isOverTarget = remaining < -0.5;
    final roundedRemaining = remaining.round();
    final remainingFormatted = numberFormat.format(
      math.max(0, roundedRemaining),
    );
    final trackColor = colors.progressTrack;
    final textTheme = Theme.of(context).textTheme;
    // Without the totals column the remaining grams get more room and size.
    final valueStyle =
        (showTotal ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Column 1: Remaining or overage value (right-aligned)
          SizedBox(
            width: showTotal ? _valueWidth : diaryQuietMacroValueWidth,
            child: DiaryScaledValueText(
              isOverTarget
                  ? '+${numberFormat.format(-roundedRemaining)}$unit'
                  : '$remainingFormatted$unit',
              style: valueStyle,
            ),
          ),
          const SizedBox(width: diaryMacroValueLabelGap),
          // Column 2: Macro label
          SizedBox(
            width: diaryMacroLabelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Column 3: 4-segment animated bar
          Expanded(
            child: DiaryAnimatedMacroBar(
              handoffTag: (#diaryMacroBar, label),
              current: current,
              target: target,
              color: color,
              trackColor: trackColor,
              isDark: isDark,
            ),
          ),
          if (showTotal) ...[
            const SizedBox(width: AppSpacing.sm),
            // Column 4: Context Current / Target
            SizedBox(
              width: _totalWidth,
              child: RichText(
                textAlign: TextAlign.right,
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: numberFormat.format(current.round()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${numberFormat.format(target.round())}$unit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
