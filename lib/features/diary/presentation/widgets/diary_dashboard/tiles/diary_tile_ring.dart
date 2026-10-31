import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// A square progress ring of a tile, the ring version of the budget card's
/// line: the eaten part from the top clockwise, the planned part after it
/// in the plan color, and the overage in the error color on top.
///
/// Without a [target] (a pause day) it only shows the eaten and the
/// planned part, measured against [scale]. A [child] sits in the middle.
class DiaryTileRing extends StatelessWidget {
  /// Creates a ring.
  const new({
    required this.eaten,
    required this.target,
    this.planned = 0,
    this.scale,
    this.eatenColor,
    this.stroke = AppDashboard.ringStroke,
    this.child,
    super.key,
  });

  /// Eaten amount.
  final double eaten;

  /// Target amount; null draws no overage.
  final double? target;

  /// Planned amount after the eaten part.
  final double planned;

  /// Amount of the full ring when [target] is null.
  final double? scale;

  /// Color of the eaten part; ink by default.
  final Color? eatenColor;

  /// Stroke width of the ring.
  final double stroke;

  /// Content in the middle.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RingPainter(
          eaten: eaten,
          planned: planned,
          target: target,
          scale: math.max<double>(target ?? scale ?? 0, 1),
          stroke: stroke,
          track: colors.track,
          eatenColor: eatenColor ?? colors.ink,
          planColor: colors.plan,
          overColor: Theme.of(context).colorScheme.error,
        ),
        child: child == null
            ? null
            : Padding(
                padding: EdgeInsets.all(stroke * 2),
                child: Center(child: child),
              ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  new({
    required this.eaten,
    required this.planned,
    required this.target,
    required this.scale,
    required this.stroke,
    required this.track,
    required this.eatenColor,
    required this.planColor,
    required this.overColor,
  });

  final double eaten;
  final double planned;
  final double? target;
  final double scale;
  final double stroke;
  final Color track;
  final Color eatenColor;
  final Color planColor;
  final Color overColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side - stroke,
      height: side - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const start = -math.pi / 2;
    const full = 2 * math.pi;
    double sweep(double value) =>
        (math.max<double>(0, value) / scale).clamp(0.0, 1.0) * full;
    void arc(double from, double length, Color color) {
      if (length <= 0) return;
      canvas.drawArc(rect, start + from, length, false, paint..color = color);
    }

    canvas.drawCircle(rect.center, rect.width / 2, paint..color = track);
    final eatenSweep = sweep(eaten);
    arc(eatenSweep, sweep(eaten + planned) - eatenSweep, planColor);
    arc(0, eatenSweep, eatenColor);
    if (target case final goal?) {
      arc(0, sweep(eaten + planned - goal), overColor);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.eaten != eaten ||
      old.planned != planned ||
      old.target != target ||
      old.scale != scale ||
      old.stroke != stroke ||
      old.track != track ||
      old.eatenColor != eatenColor ||
      old.planColor != planColor ||
      old.overColor != overColor;
}
