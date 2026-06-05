import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';

/// Animated target label above the expanded progress track.
class DiaryExpandedBalanceProgressTargetLabel extends StatelessWidget {
  /// Creates an expanded progress target label.
  const DiaryExpandedBalanceProgressTargetLabel({
    required this.width,
    required this.labelWidth,
    required this.targetRatio,
    required this.targetLabel,
    required this.colors,
    required this.isDark,
    super.key,
  });

  /// Measured track width.
  final double width;

  /// Width reserved for label placement.
  final double labelWidth;

  /// Target ratio from `0` to `1`.
  final double targetRatio;

  /// Localized target marker label.
  final String targetLabel;

  /// Active color scheme.
  final ColorScheme colors;

  /// Whether active theme is dark.
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: diaryBalanceProgressAnimationDuration,
      curve: diaryBalanceProgressAnimationCurve,
      tween: Tween<double>(begin: 0, end: targetRatio),
      builder: (context, value, child) {
        final targetCenter = width * value;
        final animatedLabelLeft = (targetCenter - labelWidth / 2).clamp(
          0.0,
          math.max<double>(0, width - labelWidth),
        );

        return Positioned(
          left: animatedLabelLeft,
          top: 0,
          width: labelWidth,
          child: child!,
        );
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppEditorialSurfaces.liftedCard(colors),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: colors.outlineVariant.withValues(
                alpha: isDark ? 0.4 : 0.58,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: isDark ? 0.22 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Text(
              targetLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
