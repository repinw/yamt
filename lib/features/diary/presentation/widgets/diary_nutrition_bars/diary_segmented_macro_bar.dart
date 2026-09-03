import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return DiarySegmentedProgressBar(
      progress: progress,
      color: color,
      trackColor: trackColor,
      isDark: isDark,
    );
  }
}
