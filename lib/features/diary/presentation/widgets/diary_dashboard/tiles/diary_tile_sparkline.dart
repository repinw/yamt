import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// A small line through [values], oldest first, with a dot on the newest.
///
/// Gaps (`null`) are skipped. The line spans at least [minRange], so small
/// swings do not look steep.
class DiaryTileSparkline extends StatelessWidget {
  /// Creates the sparkline of [values].
  const new({required this.values, required this.minRange, super.key});

  /// The values, oldest first.
  final List<double?> values;

  /// Smallest range of values the height spans.
  final double minRange;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          values: values,
          minRange: minRange,
          lineColor: colors.ink,
          dotColor: colors.accentText,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const new({
    required this.values,
    required this.minRange,
    required this.lineColor,
    required this.dotColor,
  });

  final List<double?> values;
  final double minRange;
  final Color lineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final known = values.nonNulls.toList(growable: false);
    if (known.isEmpty) return;
    final low = known.min;
    final high = known.max;
    final middle = (low + high) / 2;
    final span = high - low < minRange ? minRange : high - low;
    const inset = AppDashboard.sparklineDotRadius;
    final stepX = values.length < 2
        ? 0.0
        : (size.width - 2 * inset) / (values.length - 1);
    Offset at(int index, double value) => Offset(
      inset + index * stepX,
      size.height / 2 - (value - middle) / span * (size.height - 2 * inset),
    );

    final path = Path();
    Offset? newest;
    for (final (index, value) in values.indexed) {
      if (value == null) continue;
      final point = at(index, value);
      newest == null
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
      newest = point;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppDashboard.sparklineStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (newest != null) {
      canvas.drawCircle(
        newest,
        AppDashboard.sparklineDotRadius,
        Paint()..color = dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      !const ListEquality<double?>().equals(oldDelegate.values, values) ||
      oldDelegate.minRange != minRange ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor;
}
