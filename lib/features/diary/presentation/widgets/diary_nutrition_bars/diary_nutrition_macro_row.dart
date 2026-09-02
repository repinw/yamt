import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_segmented_macro_bar.dart';

/// Single macronutrient progress row with remaining value, label,
/// segmented bar, and consumed/target ratio.
class DiaryNutritionMacroRow extends StatelessWidget {
  /// Creates a nutrition macro row.
  const DiaryNutritionMacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.numberFormat,
    required this.unit,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final remaining = target - current;
    final isOverTarget = remaining < -0.5;
    final roundedRemaining = remaining.round();
    final remainingFormatted = numberFormat.format(
      math.max(0, roundedRemaining),
    );
    final trackColor = AppEditorialSurfaces.appBackground(colors);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Column 1: Remaining or overage value (right-aligned)
          SizedBox(
            width: 42,
            child: Text(
              isOverTarget
                  ? '+${numberFormat.format(-roundedRemaining)}$unit'
                  : '$remainingFormatted$unit',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Column 2: Macro label
          SizedBox(
            width: 44,
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
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, animatedProgress, _) {
                return DiarySegmentedMacroBar(
                  progress: animatedProgress,
                  color: color,
                  trackColor: trackColor,
                  isDark: isDark,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Column 4: Context Current / Target
          SizedBox(
            width: 68,
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
      ),
    );
  }
}
