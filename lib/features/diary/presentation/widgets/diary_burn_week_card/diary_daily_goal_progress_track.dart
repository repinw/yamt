import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';

const Duration _progressAnimationDuration = Duration(milliseconds: 1000);
const Curve _progressAnimationCurve = Curves.easeOut;
const double _activitySegmentPreviewOpacity = 0.3;

/// Animated daily kcal progress track.
class DiaryDailyGoalProgressTrack extends StatelessWidget {
  /// Creates an animated progress track for daily kcal progress.
  const DiaryDailyGoalProgressTrack({
    required this.height,
    required this.trackColor,
    required this.eatenColor,
    required this.activityColor,
    required this.eatenRatio,
    required this.activitySegmentRatio,
    required this.activityFillRatio,
    required this.activitySegmentStartRatio,
    required this.dividerColor,
    super.key,
  });

  /// Track height.
  final double height;

  /// Background track color.
  final Color trackColor;

  /// Main eaten progress color.
  final Color eatenColor;

  /// Full activity fill color.
  final Color activityColor;

  /// Eaten progress ratio from 0 to 1.
  final double eatenRatio;

  /// Activity allowance ratio from 0 to 1.
  final double activitySegmentRatio;

  /// Full-color activity ratio already covered by eaten progress.
  final double activityFillRatio;

  /// Left edge ratio where activity allowance starts.
  final double activitySegmentStartRatio;

  /// Divider color between base and activity allowance.
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ClipRRect(
          key: DiaryBalanceCardKeys.dailyProgressTrack,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: trackColor)),
                if (activitySegmentRatio > 0)
                  _ActivityPreviewSegment(
                    width: width,
                    activitySegmentRatio: activitySegmentRatio,
                    color: activityColor.withValues(
                      alpha: _activitySegmentPreviewOpacity,
                    ),
                  ),
                _EatenProgressSegment(
                  width: width,
                  eatenRatio: eatenRatio,
                  color: eatenColor,
                ),
                if (activitySegmentRatio > 0)
                  _ActivityFilledSegment(
                    width: width,
                    activityFillRatio: activityFillRatio,
                    activitySegmentStartRatio: activitySegmentStartRatio,
                    color: activityColor,
                  ),
                _ActivityDivider(
                  width: width,
                  activitySegmentRatio: activitySegmentRatio,
                  color: dividerColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityPreviewSegment extends StatelessWidget {
  const _ActivityPreviewSegment({
    required this.width,
    required this.activitySegmentRatio,
    required this.color,
  });

  final double width;
  final double activitySegmentRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _progressAnimationDuration,
      curve: _progressAnimationCurve,
      tween: Tween<double>(begin: 0, end: activitySegmentRatio),
      builder: (context, value, child) {
        if (value <= 0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: width * value,
          child: child!,
        );
      },
      child: ColoredBox(
        key: DiaryBalanceCardKeys.dailyProgressActivityPreview,
        color: color,
      ),
    );
  }
}

class _EatenProgressSegment extends StatelessWidget {
  const _EatenProgressSegment({
    required this.width,
    required this.eatenRatio,
    required this.color,
  });

  final double width;
  final double eatenRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _progressAnimationDuration,
      curve: _progressAnimationCurve,
      tween: Tween<double>(begin: 0, end: eatenRatio),
      builder: (context, value, child) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: width * value,
          child: child!,
        );
      },
      child: DecoratedBox(
        key: DiaryBalanceCardKeys.dailyProgressEatenFill,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ActivityFilledSegment extends StatelessWidget {
  const _ActivityFilledSegment({
    required this.width,
    required this.activityFillRatio,
    required this.activitySegmentStartRatio,
    required this.color,
  });

  final double width;
  final double activityFillRatio;
  final double activitySegmentStartRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _progressAnimationDuration,
      curve: _progressAnimationCurve,
      tween: Tween<double>(begin: 0, end: activityFillRatio),
      builder: (context, value, child) {
        return Positioned(
          left: width * activitySegmentStartRatio,
          top: 0,
          bottom: 0,
          width: width * value,
          child: child!,
        );
      },
      child: ColoredBox(
        key: DiaryBalanceCardKeys.dailyProgressActivityFill,
        color: color,
      ),
    );
  }
}

class _ActivityDivider extends StatelessWidget {
  const _ActivityDivider({
    required this.width,
    required this.activitySegmentRatio,
    required this.color,
  });

  final double width;
  final double activitySegmentRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _progressAnimationDuration,
      curve: _progressAnimationCurve,
      tween: Tween<double>(begin: 0, end: activitySegmentRatio),
      builder: (context, value, child) {
        if (value <= 0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          right: width * value,
          top: 0,
          bottom: 0,
          width: 1,
          child: child!,
        );
      },
      child: ColoredBox(
        color: color,
      ),
    );
  }
}
