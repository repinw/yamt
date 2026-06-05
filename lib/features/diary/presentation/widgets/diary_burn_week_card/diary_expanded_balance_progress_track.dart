import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';

/// Expanded progress track with animated consumed fill and day dividers.
class DiaryExpandedBalanceProgressTrack extends StatelessWidget {
  /// Creates an expanded progress track.
  const DiaryExpandedBalanceProgressTrack({
    required this.width,
    required this.actualConsumedRatio,
    required this.activityColor,
    required this.fatColor,
    required this.trackColor,
    required this.dividerColor,
    required this.totalDays,
    required this.progressTop,
    super.key,
  });

  /// Measured track width.
  final double width;

  /// Animated consumed ratio from `0` to `1`.
  final double actualConsumedRatio;

  /// Start color for consumed fill.
  final Color activityColor;

  /// End color for consumed fill.
  final Color fatColor;

  /// Empty track color.
  final Color trackColor;

  /// Day divider color.
  final Color dividerColor;

  /// Total days represented by this track.
  final int totalDays;

  /// Top offset within expanded progress area.
  final double progressTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: progressTop,
      child: ClipRRect(
        key: DiaryBalanceCardKeys.progressTrack,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: diaryBalanceProgressHeight,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: trackColor)),
              _AnimatedProgressFill(
                width: width,
                actualConsumedRatio: actualConsumedRatio,
                activityColor: activityColor,
                fatColor: fatColor,
              ),
              for (var day = 1; day < totalDays; day += 1)
                Positioned(
                  left: (width * day / totalDays) - 1,
                  top: 0,
                  width: 2,
                  bottom: 0,
                  child: ColoredBox(color: dividerColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressFill extends StatelessWidget {
  const _AnimatedProgressFill({
    required this.width,
    required this.actualConsumedRatio,
    required this.activityColor,
    required this.fatColor,
  });

  final double width;
  final double actualConsumedRatio;
  final Color activityColor;
  final Color fatColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: diaryBalanceProgressAnimationDuration,
      curve: diaryBalanceProgressAnimationCurve,
      tween: Tween<double>(
        begin: 0,
        end: actualConsumedRatio,
      ),
      builder: (context, value, child) {
        return Positioned(
          left: 0,
          top: 0,
          width: width * value,
          bottom: 0,
          child: child!,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              activityColor,
              fatColor,
            ],
          ),
        ),
      ),
    );
  }
}
