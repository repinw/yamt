import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_transition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

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
    this.previous,
    this.startedAt,
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

  /// Intake before this confirmed food addition.
  final double? previous;

  /// Shared start time; null for loading, editing and day changes.
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) => DiaryMacroTransition(
    current: current,
    previous: previous,
    startedAt: startedAt,
    builder: _buildRow,
  );

  Widget _buildRow(BuildContext context, double value, double highlight) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final remaining = target - value;
    final isOverTarget = remaining < -0.5;
    final roundedRemaining = remaining.round();
    final remainingFormatted = numberFormat.format(
      math.max(0, roundedRemaining),
    );
    final trackColor = colors.surface;

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
            child: DiarySegmentedProgressBar(
              progress: progress,
              color: color,
              trackColor: trackColor,
              isDark: isDark,
              highlightStart: target <= 0 || previous == null
                  ? null
                  : (previous! / target).clamp(0.0, 1.0),
              highlightOpacity: highlight,
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
                    text: numberFormat.format(value.round()),
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
