import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Multi-segment progress bar with square segments, like a food label.
class DiarySegmentedProgressBar extends StatelessWidget {
  /// Creates a segmented progress bar.
  const new({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.overflowColor,
    this.overflow = 0.0,
    this.segmentCount = 4,
    this.height = 6.0,
    this.spacing = 3.0,
    super.key,
  });

  /// Fill progress clamped between 0.0 and 1.0.
  final double progress;

  /// Share of the bar, from its right end, that is striped to mark an
  /// overage. Between 0.0 and 1.0.
  final double overflow;

  /// Active fill color.
  final Color color;

  /// Track background color.
  final Color trackColor;

  /// Color of the overage stripes. Defaults to [color].
  final Color? overflowColor;

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
        final stripedFill =
            ((segmentEnd - math.max(segmentStart, 1 - overflow)) /
                    (segmentEnd - segmentStart))
                .clamp(0.0, 1.0);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < count - 1 ? spacing : 0.0),
            child: Container(
              height: height,
              color: trackColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: segmentFill,
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                  if (stripedFill > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: stripedFill,
                        // A childless CustomPaint would otherwise shrink to
                        // zero height.
                        heightFactor: 1,
                        child: CustomPaint(
                          painter: _OverflowStripePainter(
                            color: overflowColor ?? color,
                            background: trackColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Paints diagonal [color] stripes on [background].
class _OverflowStripePainter extends CustomPainter {
  const new({required this.color, required this.background});

  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final stripe = Paint()
      ..color = color
      ..strokeWidth = AppSizes.overflowStripeWidth;
    for (
      var x = -size.height;
      x < size.width;
      x += AppSizes.overflowStripeSpacing
    ) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_OverflowStripePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.background != background;
}
