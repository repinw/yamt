import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Four-segment animated progress bar for an individual macronutrient.
class DiarySegmentedMacroBar extends StatelessWidget {
  /// Creates a segmented macronutrient bar.
  const DiarySegmentedMacroBar({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
    super.key,
  });

  /// Fill progress clamped between 0.0 and 1.0.
  final double progress;

  /// Active fill color for this macro.
  final Color color;

  /// Track background color.
  final Color trackColor;

  /// Whether the current theme is dark mode.
  final bool isDark;

  static const _segmentCount = 4;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_segmentCount, (index) {
        final segmentStart = index / _segmentCount;
        final segmentEnd = (index + 1) / _segmentCount;
        final segmentFill =
            ((progress - segmentStart) / (segmentEnd - segmentStart)).clamp(
              0.0,
              1.0,
            );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < _segmentCount - 1 ? 3.0 : 0.0,
            ),
            child: Container(
              height: 6,
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
