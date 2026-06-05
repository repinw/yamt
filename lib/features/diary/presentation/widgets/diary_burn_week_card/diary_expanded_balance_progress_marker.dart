import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';

/// Animated target marker over the expanded progress track.
class DiaryExpandedBalanceProgressMarker extends StatelessWidget {
  /// Creates an expanded progress target marker.
  const DiaryExpandedBalanceProgressMarker({
    required this.width,
    required this.targetRatio,
    required this.colors,
    required this.progressTop,
    super.key,
  });

  /// Measured track width.
  final double width;

  /// Target ratio from `0` to `1`.
  final double targetRatio;

  /// Active color scheme.
  final ColorScheme colors;

  /// Top offset of the progress track.
  final double progressTop;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: diaryBalanceProgressAnimationDuration,
      curve: diaryBalanceProgressAnimationCurve,
      tween: Tween<double>(begin: 0, end: targetRatio),
      builder: (context, value, child) {
        final targetCenter = width * value;
        final animatedMarkerLeft =
            (targetCenter - diaryBalanceTargetMarkerWidth / 2).clamp(
              0.0,
              math.max<double>(0, width - diaryBalanceTargetMarkerWidth),
            );

        return Positioned(
          left: animatedMarkerLeft,
          top: progressTop - diaryBalanceTargetMarkerOverflowTop,
          child: child!,
        );
      },
      child: Container(
        key: DiaryBalanceCardKeys.targetMarker,
        width: diaryBalanceTargetMarkerWidth,
        height:
            diaryBalanceProgressHeight +
            diaryBalanceTargetMarkerOverflowTop +
            8,
        decoration: BoxDecoration(
          color: colors.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
