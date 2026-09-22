import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

/// Multi-segment skeleton loader bar matching the diary segmented progress bar.
class DiarySegmentedSkeletonBar extends StatelessWidget {
  /// Creates a segmented skeleton bar.
  const new({
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
            padding: EdgeInsets.only(right: index < count - 1 ? spacing : 0.0),
            child: MetricSkeletonBlock(height: height, color: color),
          ),
        );
      }),
    );
  }
}
