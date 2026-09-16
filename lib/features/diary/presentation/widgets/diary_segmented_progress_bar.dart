import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

/// Animated multi-segment progress bar with rounded pill capsules.
class DiarySegmentedProgressBar extends StatelessWidget {
  /// Creates a segmented progress bar.
  const DiarySegmentedProgressBar({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
    this.segmentCount = 4,
    this.height = 6.0,
    this.spacing = 3.0,
    super.key,
  });

  /// Fill progress clamped between 0.0 and 1.0.
  final double progress;

  /// Active fill color.
  final Color color;

  /// Track background color.
  final Color trackColor;

  /// Whether the current theme is dark mode.
  final bool isDark;

  /// Number of segments in the bar.
  final int segmentCount;

  /// Height of each segment.
  final double height;

  /// Space between adjacent segments.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final count = segmentCount > 0 ? segmentCount : 1;

    return Row(
      children: List.generate(count, (index) {
        final segmentStart = index / count;
        final segmentEnd = (index + 1) / count;
        final segmentFill =
            ((progress - segmentStart) / (segmentEnd - segmentStart)).clamp(
              0.0,
              1.0,
            );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < count - 1 ? spacing : 0.0,
            ),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: segmentFill,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: segmentFill > 0
                        ? [
                            BoxShadow(
                              color: color.withValues(
                                alpha: isDark ? 0.35 : 0.42,
                              ),
                              blurRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Multi-segment skeleton loader bar matching [DiarySegmentedProgressBar].
class DiarySegmentedSkeletonBar extends StatelessWidget {
  /// Creates a segmented skeleton bar.
  const DiarySegmentedSkeletonBar({
    required this.segmentCount,
    required this.color,
    this.height = 6.0,
    this.spacing = 3.0,
    super.key,
  });

  /// Number of segments.
  final int segmentCount;

  /// Skeleton fill color.
  final Color color;

  /// Height of each segment.
  final double height;

  /// Space between adjacent segments.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final count = segmentCount > 0 ? segmentCount : 1;

    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < count - 1 ? spacing : 0.0,
            ),
            child: MetricSkeletonBlock(
              height: height,
              color: color,
            ),
          ),
        );
      }),
    );
  }
}
